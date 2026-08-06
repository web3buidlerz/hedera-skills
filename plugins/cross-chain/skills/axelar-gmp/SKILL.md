---
name: axelar-gmp
description: >
  Axelar General Message Passing (GMP) on Hedera. Use when sending or receiving cross-chain
  contract calls via Axelar Gateway (callContract, payNativeGasForContractCall), building
  AxelarExecutable receivers, wiring Hedera↔EVM destinations, or implementing bridge-sender /
  message-receiver patterns for orchestrated flows (e.g. scheduled DCA to Sepolia).
---

# Axelar GMP (Hedera)

**GMP pattern:** encode a payload on the source chain, pay Axelar gas in native token, call the Gateway, then decode and act on the destination behind an allowlisted source.

```text
Source app → BridgeSender (pay gas + gateway.callContract)
                 → Axelar relayers
                      → AxelarExecutable._execute → Handler
```

On Hedera, orchestration often pairs GMP with **HSS** (`0x16b`) so a contract can self-reschedule and dispatch each cycle. Keep bridge transport behind `IBridgeSender` so the orchestrator stays bridge-agnostic.

## Quick Reference

| Piece | Role |
| ----- | ---- |
| `IAxelarGateway` | `callContract(destChain, destAddress, payload)` |
| `IAxelarGasService` | `payNativeGasForContractCall{value}` before the gateway call |
| `AxelarExecutable` | Destination base; override `_execute(...)` |
| Chain names | Axelar string IDs — e.g. source `"hedera"`, dest `"ethereum-sepolia"` |
| Addresses | EVM string form of the peer contract (checksummed `0x…`) |

**Hedera testnet defaults** (re-check [Axelar docs](https://docs.axelar.dev/) before mainnet):

| Contract | Address |
| -------- | ------- |
| Gateway (Hedera + Sepolia often same canonical) | `0xe432150cce91c13a887f7D836923d5597adD8E31` |
| Gas service (Hedera) | `0xbE406F0189A0B4cf3A05C286473D23791Dd44Cc6` |

See [references/hedera-axelar.md](references/hedera-axelar.md) for env vars and wiring. See [references/examples.md](references/examples.md) for full sender / receiver / orchestrator skeletons.

## Critical: Gas Then Gateway

Always pay gas **before** `callContract`. Use `msg.value > 0` for relay fees; refund address should be the funded orchestrator (or plan owner), not a random EOA.

```solidity
gasService.payNativeGasForContractCall{ value: msg.value }(
    address(this),       // sender contract
    destinationChain,    // e.g. "ethereum-sepolia"
    destinationAddress,  // receiver 0x… as string
    payload,
    refundAddress        // usually authorizedCaller / orchestrator
);
gateway.callContract(destinationChain, destinationAddress, payload);
```

## Critical: Authorize And Allowlist

| Side | Guard |
| ---- | ----- |
| Source sender | Only `authorizedCaller` (orchestrator) may `send` |
| Destination receiver | Validate `srcChain` + `srcAddress` (case-insensitive) before handling |
| Destination handler | Only the receiver may call business logic (`authorizedCaller`) |

Compare Axelar chain/address strings with a shared lowercase hash — Axelar may vary casing.

```solidity
require(
    keccak256(bytes(_toLower(srcChain))) == keccak256(bytes(_toLower(expectedSourceChain))),
    "invalid source chain"
);
require(
    keccak256(bytes(_toLower(srcAddress))) == keccak256(bytes(_toLower(expectedSourceAddress))),
    "invalid source address"
);
```

## Architecture: Split Transport From Business Logic

```text
Hedera                          Destination (e.g. Sepolia)
─────────────────────────────   ─────────────────────────────
DcaOrchestrator ──send──►       AxelarMessageReceiver (_execute)
     │ IBridgeSender                    │ IDcaHandler
AxelarMessageSender             DcaExecutor (swap / settle)
```

1. Deploy **handler** first (no bridge knowledge).
2. Deploy **receiver** with gateway + expected source + handler.
3. Deploy **sender** with gateway + gas service + destination chain/address.
4. Deploy **orchestrator** with sender address; `sender.setAuthorizedCaller(orchestrator)`.
5. **Wire** after both deploys: set destination on sender; set expected source on receiver.
6. Fund orchestrator (native for Axelar gas) and handler (tokens for destination work).

## Payload Contract

Agree a single ABI encode/decode on both sides:

```solidity
bytes memory payload = abi.encode(planId, amountPerExecution, targetToken, minAmountOut);
// receiver:
(uint256 planId, uint256 amountIn, address tokenOut, uint256 minAmountOut) =
    abi.decode(payload, (uint256, uint256, address, uint256));
```

Keep payloads versionable if you evolve fields — mismatched decode bricks the route.

## Hedera Orchestration Hook (HSS)

When the source app schedules itself via HSS, each `executeDca` (or equivalent) should:

1. Enforce interval / plan active
2. `bridgeSender.send{ value: feeForSender }(...)`
3. Reschedule next expiry with `hasScheduleCapacity` + `scheduleCall` (SUCCESS = `22`)

If scheduling fails, mark `needsReschedule` and expose a manual `reschedule` for the plan owner.

## Checklist

- [ ] Gas paid with native value before `callContract`
- [ ] Destination chain name matches Axelar’s ID (`ethereum-sepolia`, not `11155111`)
- [ ] Peer addresses set after both contracts deploy (wire step)
- [ ] Source allowlist + authorized callers on both ends
- [ ] Payload encode/decode identical
- [ ] Orchestrator funded for relay gas; destination handler funded for work
- [ ] Demo vs production: clarify who owns destination proceeds

## References

- [references/examples.md](references/examples.md) — sender, receiver, orchestrator, executor
- [references/hedera-axelar.md](references/hedera-axelar.md) — addresses, chain names, env
- [Axelar GMP overview](https://docs.axelar.dev/dev/general-message-passing/overview)
- [axelar-gmp-sdk-solidity](https://github.com/axelarnetwork/axelar-gmp-sdk-solidity)
- Source template: [scaffold-hbar `templates/cross-chain-dca`](https://github.com/hedera-dev/scaffold-hbar/tree/templates/cross-chain-dca)
