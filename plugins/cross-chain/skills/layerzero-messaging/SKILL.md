---
name: layerzero-messaging
description: >
  LayerZero V2 messaging on Hedera. Use when building OFT / OApp bridges between Hedera and
  EVM chains, configuring Endpoint V2 peers and ULN/DVN/executor wiring, sending with
  quoteSend + send, implementing HTS-backed OFT connectors (mint/burn via 0x167), or
  relaying educational lzReceive flows on testnet.
---

# LayerZero Messaging (Hedera)

**OFT pattern:** deploy paired Omnichain Fungible Tokens — a standard `OFT` on the EVM side and an **HTS connector OFT** on Hedera — then `setPeer` both ways and send with LayerZero V2 fees.

```text
MyOFT (Sepolia)  ←setPeer→  MyHTSConnectorOFT (Hedera)
       │ send / quoteSend          │ _debit burn / _credit mint (HTS 0x167)
       └──────── Endpoint V2 + ULN + DVN + Executor ────────┘
```

This skill focuses on **LayerZero V2 OApp/OFT + Hedera HTS**. Educational templates may use **simple workers** and a manual/UI `lzReceive` relay — not the same as production LayerZero Labs verification.

## Quick Reference

| Concept | Rule |
| ------- | ---- |
| Endpoint | `ILayerZeroEndpointV2` per chain |
| Peer | `setPeer(remoteEid, bytes32(uint256(uint160(remoteOApp))))` on **both** sides |
| Send | `quoteSend(SendParam, payInLzToken)` → `send{value: nativeFee}(SendParam, fee, refund)` |
| Receiver | `to` in `SendParam` is `bytes32` (padded address) |
| Hedera OFT | `HTSConnector` / `MyHTSConnectorOFT` — create HTS token, burn on send, mint on receive |
| HTS fee | Deploy connector with native value (template uses ~`40 ether` / 20+ HBAR via JSON-RPC rescale) |
| Approval | User must `approve(connector, amount)` on the **HTS token** before Hedera → EVM `send` |

**Testnet EIDs / endpoints** (from template `HelperConfig`; re-check [LayerZero deployments](https://metadata.layerzero-api.com/v1/metadata/deployments)):

| Network | Chain ID | EID | Endpoint V2 |
| ------- | -------- | --- | ----------- |
| Hedera testnet | `296` | `40285` | `0xbD672D1562Dd32C23B563C989d8140122483631d` |
| Ethereum Sepolia | `11155111` | `40161` | `0x6EDCE65403992e310A62460808c4b910D972f10f` |

See [references/hedera-endpoints.md](references/hedera-endpoints.md) for ULN/DVN/executor addresses. See [references/examples.md](references/examples.md) for contract and wire snippets.

## Critical: Wire Both Directions

Incomplete peer config bricks the pathway. For each local OApp:

1. `setPeer(remoteEid, remoteOAppAsBytes32)`
2. `setSendLibrary` / `setReceiveLibrary` (ULN302)
3. `setConfig` — ExecutorConfig (type `1`) on send lib; UlnConfig (type `2`) on send + receive libs
4. `setEnforcedOptions` — e.g. `lzReceive` gas for msgType `1` (token send)

Verify with `peers(remoteEid)` on both chains before sending.

## Critical: Hedera HTS Connector Semantics

On Hedera, do **not** use a plain ERC-20 OFT as the primary path. Use an HTS-backed connector:

- Constructor creates fungible HTS via precompile `0x167` (supply key = connector)
- `_debit`: transfer HTS in → **burn**
- `_credit`: **mint** → transfer HTS out
- Amounts must fit `int64` for HTS mint/burn/transfer
- Associate the receiver account with the HTS token before Sepolia → Hedera receives

```solidity
// Deploy with value so createFungibleToken fee is paid
new MyHTSConnectorOFT{ value: htsCreateValue }(name, symbol, lzEndpoint, owner);
```

## Send Flow

```solidity
SendParam memory sendParam = SendParam({
    dstEid: remoteEid,
    to: bytes32(uint256(uint160(receiver))),
    amountLD: amountLD,
    minAmountLD: (amountLD * 9) / 10,
    extraOptions: OptionsBuilder.newOptions().addExecutorLzReceiveOption(80_000, 0),
    composeMsg: "",
    oftCmd: ""
});

MessagingFee memory fee = IOFT(localOFT).quoteSend(sendParam, false);
IOFT(localOFT).send{ value: fee.nativeFee }(sendParam, fee, payable(refundTo));
```

**Hedera → Sepolia note:** forge fee simulation can disagree with Hedera JSON-RPC wei/tinybar scaling — templates often `quote` + `cast send` for that direction.

## Deploy Checklist (testnet)

1. Deploy Sepolia `MyOFT` (optional premint)
2. Deploy Hedera `MyHTSConnectorOFT` with HTS create value
3. Deploy workers (Labs DVN/executor **or** educational simple workers)
4. Wire Sepolia OApp ↔ Hedera OApp (`WireOApp` both ways)
5. Associate Hedera account with `htsTokenAddress()`
6. Sync frontend config; fund relay key if using UI auto-relay
7. Send small amount; track on [LayerZero Scan testnet](https://testnet.layerzeroscan.com)

## Educational Relay

Some templates use **SimpleDVNMock** / **SimpleExecutorMock** and an explicit `lzReceive` relay step (`make layerzero-relay` or Next.js `LAYERZERO_RELAY_PRIVATE_KEY`). Treat that as a learning aid — production apps rely on LayerZero’s verification network, not a custom relayer key in the app server.

## Checklist

- [ ] Peers set both ways with correct EIDs (not EVM chain IDs)
- [ ] Send/receive libraries + ULN/executor config applied
- [ ] Hedera side is HTS connector; create fee paid; supply key is connector
- [ ] Receiver associated with HTS token before inbound transfers
- [ ] `quoteSend` native fee attached to `send`
- [ ] Receiver address encoded as `bytes32`
- [ ] Educational disclaimer: not audited / not for mainnet funds

## References

- [references/examples.md](references/examples.md) — MyOFT, HTSConnector, wire, send
- [references/hedera-endpoints.md](references/hedera-endpoints.md) — EIDs, Endpoint V2, ULN, DVN, executor
- [LayerZero V2 docs](https://docs.layerzero.network/v2)
- [LayerZero deployments metadata](https://metadata.layerzero-api.com/v1/metadata/deployments)
- Source template: [scaffold-hbar `templates/bridge`](https://github.com/hedera-dev/scaffold-hbar/tree/templates/bridge)
