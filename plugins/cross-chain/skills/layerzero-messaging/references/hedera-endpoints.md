# Hedera LayerZero V2 Endpoints

Values from Scaffold-HBAR `templates/bridge` `script/layerzero/HelperConfig.s.sol` and `services/bridge/config/layerzero.json`. Re-check [LayerZero deployments metadata](https://metadata.layerzero-api.com/v1/metadata/deployments) before mainnet.

## Chain IDs vs EIDs

| Network | EVM chain ID | LayerZero EID |
| ------- | ------------ | ------------- |
| Hedera testnet | `296` | `40285` |
| Ethereum Sepolia | `11155111` | `40161` |

Use **EIDs** in `setPeer`, `SendParam.dstEid`, and library config — not EVM chain IDs.

## Hedera testnet (`296` / EID `40285`)

| Role | Address |
| ---- | ------- |
| Endpoint V2 | `0xbD672D1562Dd32C23B563C989d8140122483631d` |
| Send ULN302 | `0x1707575F7cEcdC0Ad53fde9ba9bda3Ed5d4440f4` |
| Receive ULN302 | `0xc0c34919A04d69415EF2637A3Db5D637a7126cd0` |
| Executor (LZ Labs) | `0xe514D331c54d7339108045bF4794F8d71cad110e` |
| DVN (LZ Labs) | `0xEc7Ee1f9e9060e08dF969Dc08EE72674AfD5E14D` |

Remote EID from Hedera: `40161` (Sepolia).

## Sepolia (`11155111` / EID `40161`)

| Role | Address |
| ---- | ------- |
| Endpoint V2 | `0x6EDCE65403992e310A62460808c4b910D972f10f` |
| Send ULN302 | `0xcc1ae8Cf5D3904Cef3360A9532B477529b177cCE` |
| Receive ULN302 | `0xdAf00F5eE2158dD58E0d3857851c432E34A3A851` |
| Executor (LZ Labs) | `0x718B92b5CB0a5552039B593faF724D182A881eDA` |
| DVN (LZ Labs) | `0x8eebf8b423B73bFCa51a1Db4B7354AA0bFCA9193` |

Remote EID from Sepolia: `40285` (Hedera testnet).

## Hedera-specific knobs (template)

| Item | Typical value / note |
| ---- | -------------------- |
| HTS precompile | `0x167` |
| HTS create deploy value | `HEDERA_HTS_CREATE_VALUE` (e.g. `40ether` via JSON-RPC) |
| Deploy / transfer gas limit | often `15_000_000` on Hedera |
| Enforced `lzReceive` gas | `80_000` (msgType `1`) |
| Educational relay `lzReceive` gas | `500_000` |

## Packages

```text
@layerzerolabs/lz-evm-protocol-v2
@layerzerolabs/lz-evm-oapp-v2
@layerzerolabs/lz-evm-messagelib-v2
```

## Ops

- Track messages on [LayerZero Scan testnet](https://testnet.layerzeroscan.com)
- Frontend sync: `make bridge-sync-next PROVIDER=layerzero`
- UI auto-relay (educational): `LAYERZERO_RELAY_PRIVATE_KEY` in Next.js env (testnet-only key)
