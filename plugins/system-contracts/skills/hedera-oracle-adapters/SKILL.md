---
name: hedera-oracle-adapters
description: >
  Hedera price oracle adapters. Use when integrating Chainlink, Supra, or Pyth price feeds on
  Hedera (testnet 296 / mainnet 295), implementing IPriceOracle, normalizing prices to 18 decimals,
  building consumer conversion flows, or switching provider adapters via setOracle.
---

# Hedera Oracle Adapters

**Adapter pattern:** each provider feed is wrapped by a multi-pair adapter that implements one shared `IPriceOracle` interface. Consumers read `latestPrice(pairKey)` and convert amounts with `priceE18` — they never call Chainlink/Supra/Pyth APIs directly.

```text
Provider feed -> Multi-pair provider adapter -> Consumer
```

Switch providers by deploying another adapter and pointing the consumer at it (`setOracle`).

## Quick Reference

| Concept | Rule |
| ------- | ---- |
| Interface | `IPriceOracle.latestPrice(bytes32 pairKey) → PriceData` |
| Price scale | Always **18 decimals** (`priceE18`) |
| Pair key | `keccak256(abi.encode(BASE, QUOTE))` — uppercase symbols (`HBAR`, `USD`) |
| Provider key | `keccak256("CHAINLINK" \| "SUPRA" \| "PYTH")` |
| Freshness | Each adapter enforces `MAX_STALENESS`; stale reads **revert** |
| Config | Constructor-only pair maps; no post-deploy pair edits |

**Hedera chain IDs:** testnet `296`, mainnet `295`.

See [references/examples.md](references/examples.md) for libs and read patterns. See [references/hedera-feeds.md](references/hedera-feeds.md) for where to source feed / pair / price IDs.

## Critical: Normalize And Revert

Adapters must **never** return invalid prices. Revert with shared errors:

| Error | When |
| ----- | ---- |
| `OracleUnsupportedPair(pairKey)` | Pair not configured |
| `OracleIncompleteRound()` | Missing / unfinished upstream round |
| `OracleInvalidPrice()` | Zero or non-positive price |
| `OracleStalePrice(updatedAt, maxStaleness)` | Older than `MAX_STALENESS` |

```solidity
interface IPriceOracle {
    struct PriceData {
        bytes32 pairKey;
        bytes32 providerKey;
        uint256 priceE18;   // one whole BASE in QUOTE units, 18 decimals
        uint256 updatedAt;  // unix seconds
    }

    function latestPrice(bytes32 pairKey) external view returns (PriceData memory data);
}
```

## Pair And Provider Keys

```solidity
// PairLib — casing is significant; do not mix `HBAR` / `hbar`
bytes32 key = keccak256(abi.encode("HBAR", "USD"));

// ProviderLib constants
bytes32 constant CHAINLINK = keccak256("CHAINLINK");
bytes32 constant SUPRA     = keccak256("SUPRA");
bytes32 constant PYTH      = keccak256("PYTH");
```

## Provider Quirks

Deploy **one adapter contract per provider**. Each supports multiple pairs in one deployment.

### Chainlink (push / Data Feeds)

- Map: `pairKey → AggregatorV3Interface feed`
- Read: `latestRoundData()` — require `answeredInRound >= roundId`, `updatedAt != 0`, `answer > 0`
- Normalize feed decimals → 18

### Supra (push S-Value)

- Map: `pairKey → supraPairId` (+ immutable push-oracle address)
- Read: `getSvalue(pairId)`
- **Hedera quirk:** Supra timestamps are often **milliseconds** — convert to seconds when `time > 1e10`
- **Hedera quirk:** current feeds are often **USDT** pairs (not USD) — pair keys must match (`HBAR`/`USDT`)

```solidity
uint256 updatedAt = pf.time > 10_000_000_000 ? pf.time / 1_000 : pf.time;
```

### Pyth (pull)

- Map: `pairKey → bytes32 priceId`
- **Pull model:** call payable `updatePrice(updateData)` with Hermes payloads **before** reads when stale
- Read: `getPriceNoOlderThan(priceId, MAX_STALENESS)`
- Reject when `conf > uint64(price)` (confidence wider than price)
- Normalize signed price + `expo` → 18 decimals

```solidity
function updatePrice(bytes[] calldata updateData) external payable {
    uint256 fee = PYTH.getUpdateFee(updateData);
    if (msg.value < fee) revert PythUpdateFeeTooLow(msg.value, fee);
    PYTH.updatePriceFeeds{ value: msg.value }(updateData);
}
```

## Consumer Pattern

Keep business logic on a thin consumer that holds one `IPriceOracle` and converts with shared math:

```solidity
IPriceOracle.PriceData memory data = oracle.latestPrice(pairKey);
return AssetConversionLib.baseToQuote(
    baseAmount, baseDecimals, quoteDecimals, data.priceE18
);
```

Conversion (rounds down via `Math.mulDiv`):

```text
quoteAmount = baseAmount * 10^quoteDecimals / 10^baseDecimals * priceE18 / 1e18
baseAmount  = quoteAmount * 10^baseDecimals / 10^quoteDecimals * 1e18 / priceE18
```

Switch later with `setOracle(newAdapter)` — no consumer redeploy.

## Deployment Flow

1. Store network-specific feed addresses / pair IDs / price IDs in a config helper (chainId → configs). Unsupported chain IDs should revert.
2. Deploy one provider adapter with its constructor config array
3. Deploy (or point) a consumer at the chosen adapter
4. Switch providers later with `setOracle`

## Adding A Pair

1. Add feed / pair ID / price ID to the network config for the target chain
2. Include the pair in the adapter deploy script’s config array
3. Redeploy the adapter (constructor-only config) and point the consumer at it

## Checklist

When implementing or reviewing oracle code on Hedera:

- [ ] Consumer depends only on `IPriceOracle`, not provider SDKs
- [ ] All adapters return `priceE18` and share the same error vocabulary
- [ ] Pair/provider keys use canonical uppercase strings
- [ ] Stale, incomplete, and non-positive prices revert
- [ ] Supra timestamps normalized to unix seconds; USDT pairs where USD unavailable
- [ ] Pyth updates paid with `msg.value` before fresh reads
- [ ] Feeds/IDs taken from Hedera-specific docs (not Ethereum defaults)

## References

- [references/examples.md](references/examples.md) — PairLib, conversion, provider read sketches
- [references/hedera-feeds.md](references/hedera-feeds.md) — where to source Hedera feed / pair / price IDs
- [Chainlink Data Feeds](https://docs.chain.link/data-feeds)
- [Supra push oracle networks](https://docs.supra.com/oracles/data-feeds/push-oracle/networks)
- [Pyth Price Feeds](https://docs.pyth.network/price-feeds)
