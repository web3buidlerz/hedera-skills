# Hedera ↔ Axelar Addresses And Names

Values from Scaffold-HBAR `templates/cross-chain-dca` (`packages/hardhat/.env.example`). Re-check [Axelar network configs](https://docs.axelar.dev/resources/contract-addresses/testnet) before mainnet.

## Chain IDs vs Axelar names

| Network | EVM chain ID | Axelar GMP name (typical) |
| ------- | ------------ | ------------------------- |
| Hedera testnet | `296` | `hedera` |
| Ethereum Sepolia | `11155111` | `ethereum-sepolia` |

Pass **Axelar names** to `callContract` / allowlists — not numeric chain IDs.

## Testnet contracts

| Role | Env var | Address |
| ---- | ------- | ------- |
| Hedera gateway | `AXELAR_GATEWAY_HEDERA` | `0xe432150cce91c13a887f7D836923d5597adD8E31` |
| Hedera gas service | `AXELAR_GAS_SERVICE_HEDERA` | `0xbE406F0189A0B4cf3A05C286473D23791Dd44Cc6` |
| Sepolia gateway | `AXELAR_GATEWAY_SEPOLIA` | `0xe432150cce91c13a887f7D836923d5597adD8E31` |

## Env shape

```bash
# Hedera side
AXELAR_GATEWAY_HEDERA=0xe432150cce91c13a887f7D836923d5597adD8E31
AXELAR_GAS_SERVICE_HEDERA=0xbE406F0189A0B4cf3A05C286473D23791Dd44Cc6
AXELAR_DESTINATION_CHAIN_NAME=ethereum-sepolia

# Sepolia side
AXELAR_GATEWAY_SEPOLIA=0xe432150cce91c13a887f7D836923d5597adD8E31
AXELAR_SOURCE_CHAIN_NAME=hedera
```

Destination / source **contract** addresses are set at deploy/wire time (not fixed in env):

- Hedera sender → `setDestinationAddress(sepoliaReceiver)`
- Sepolia receiver → `setExpectedSourceAddress(hederaSender)` (and matching source chain name)

## SDK dependency

```text
@axelar-network/axelar-gmp-sdk-solidity
```

Imports used by the template:

- `contracts/interfaces/IAxelarGateway.sol`
- `contracts/interfaces/IAxelarGasService.sol`
- `contracts/executable/AxelarExecutable.sol`

## Operational notes

- Fund the **orchestrator** with native HBAR so each `send{value: feeForSender}` can pay Axelar gas.
- Fund the **destination handler** with the tokens it spends (e.g. USDC for Uniswap).
- Track delivery on [Axelarscan](https://axelarscan.io/) / testnet explorers when debugging stuck GMP messages.
- Demo templates may keep destination proceeds in the executor contract — document ownership before production.
