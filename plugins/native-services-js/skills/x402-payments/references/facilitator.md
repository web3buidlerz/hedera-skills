# Hedera x402 Facilitator

Values and behavior from Scaffold-HBAR `templates/x402-pay-per-use` (`facilitator/` + root `docker-compose.yml`). Re-check [x402 docs](https://docs.x402.org) and [`@x402/hedera`](https://www.npmjs.com/package/@x402/hedera) for protocol updates.

## Endpoints

| Method | Path | Purpose |
| ------ | ---- | ------- |
| `GET` | `/supported` | Supported payment kinds + fee-payer account clients must use |
| `POST` | `/verify` | Validate signed payment payload against requirements |
| `POST` | `/settle` | Co-sign as fee payer, submit to Hedera, await SUCCESS |
| `GET` | `/health` | Liveness |

Non-custodial: facilitator only adds the fee-payer signature to a transfer the buyer already authorized. It never holds file bytes or the buyer’s funds.

## Environment

| Env var | Default | Description |
| ------- | ------- | ----------- |
| `PORT` | `4020` | HTTP port |
| `X402_NETWORK` | `hedera:testnet` | CAIP-2 network for settle |
| `FACILITATOR_ACCOUNT_ID` | _(required)_ | Funded ECDSA fee-payer account id |
| `FACILITATOR_PRIVATE_KEY` | _(required)_ | ECDSA key for co-sign + submit |
| `HEDERA_NODE_URL` | _(optional)_ | Custom consensus endpoint |

Resource server (Next.js) only needs `FACILITATOR_URL` (e.g. `http://localhost:4020`) — **not** the private key.

## Why ECDSA + fee payer

Hedera x402 uses native `TransferTransaction`s. Wallets such as HashPack partially sign (buyer → seller). Settle requires the facilitator to:

1. Match buyer signature to requirements (`payTo`, amount tinybars, asset `0.0.0`)
2. Co-sign as the fee payer advertised on `/supported`
3. Pay network fees and submit until receipt status SUCCESS

Use a dedicated funded ECDSA account — not the contract deployer or seller wallet.

## Docker (template)

```bash
yarn infra:up    # MinIO :9000/:9001 + facilitator :4020
yarn infra:down
```

Compose services: `minio`, `minio-init` (private bucket), `facilitator` (build `./facilitator`).

## Packages

```text
@x402/core
@x402/hedera
```

Scheme paths used by the template:

```text
@x402/hedera/exact/server      # resource server
@x402/hedera/exact/client      # browser / CLI client
@x402/hedera/exact/facilitator # self-hosted facilitator
```
