# Hedera Oracle Feed Sources

Concrete feed addresses, Supra pair IDs, and Pyth price IDs are **project-specific**. Prefer the consuming repo’s `HelperConfig` / `AGENTS.md` (or equivalent) over hardcoding values from this skill.

Always re-check provider docs before mainnet use — addresses and IDs can change.

## Chain IDs

| Network | Chain ID |
| ------- | -------- |
| Hedera mainnet | `295` |
| Hedera testnet | `296` |

## Where To Look

| Provider | What you need | Docs |
| -------- | ------------- | ---- |
| Chainlink | AggregatorV3 feed addresses per pair | [Hedera price feeds](https://docs.chain.link/data-feeds/price-feeds/addresses?network=hedera) |
| Supra | Push-oracle address + numeric pair IDs | [Push oracle networks](https://docs.supra.com/oracles/data-feeds/push-oracle/networks), [data feeds index](https://docs.supra.com/oracles/data-feeds/data-feeds-index) |
| Pyth | Pyth contract address + `bytes32` price IDs | [EVM contract addresses](https://docs.pyth.network/price-feeds/core/contract-addresses/evm), [Hermes price feeds](https://hermes.pyth.network/v2/price_feeds) |

## Hedera-Specific Notes

- **Supra** on Hedera currently exposes **USDT** pairs more often than USD — pair keys must use `USDT` when that is what the feed quotes.
- **Pyth** is pull-based: fetch update payloads from Hermes before calling a payable `updatePrice` / `updatePriceFeeds`.
- Do **not** reuse Ethereum mainnet feed addresses on Hedera.
