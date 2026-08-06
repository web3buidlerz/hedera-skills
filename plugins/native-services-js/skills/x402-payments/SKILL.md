---
name: x402-payments
description: >
  x402 pay-per-use payments on Hedera. Use when gating HTTP resources behind native HBAR
  payments, wiring a self-hosted Hedera facilitator (verify/settle), building
  x402ResourceServer / ExactHederaScheme flows, integrating HashPack WalletConnect
  payment retries (PAYMENT-REQUIRED → PAYMENT-SIGNATURE), or registering FileRegistry
  metadata (priceTinybar, payToAccountId) for private downloads.
---

# x402 Payments (Hedera)

**Pay-per-use pattern:** store bytes off-chain (private MinIO/S3), register access terms on-chain (`FileRegistry`), gate downloads with **HTTP 402** + a **self-hosted Hedera facilitator** that verifies and settles native HBAR transfers.

```text
Buyer → GET /api/files/:id/download
          ├─ public / free → presigned URL
          └─ private → 402 PAYMENT-REQUIRED
                → client signs HBAR transfer (HashPack)
                → retry with PAYMENT-SIGNATURE
                → resource server verify + settle via facilitator
                → PAYMENT-RESPONSE + short-lived download URL
```

The Next.js resource server **never holds facilitator keys**. Settlement uses a funded **ECDSA** fee-payer account on the facilitator process.

## Quick Reference

| Piece | Role |
| ----- | ---- |
| `FileRegistry` | On-chain metadata: owner, `payToAccountId`, `priceTinybar`, `isPublic`, `objectKey`, `contentHash` |
| `PAYMENT_ASSET` / `HBAR_ASSET` | `"0.0.0"` — native HBAR; amounts in **tinybars** (1 HBAR = 1e8) |
| Resource server | `@x402/core` + `ExactHederaScheme` → talks to facilitator over HTTP |
| Facilitator | `GET /supported`, `POST /verify`, `POST /settle`, `GET /health` |
| Client | Request → read 402 → sign → retry with `PAYMENT-SIGNATURE` (legacy `X-PAYMENT` also accepted) |
| Wallet | HashPack via WalletConnect / UniversalProvider; ECDSA Hedera account |

**Local defaults** (from Scaffold-HBAR `templates/x402-pay-per-use`):

| Service | URL / note |
| ------- | ---------- |
| Facilitator | `http://localhost:4020` (`FACILITATOR_URL`) |
| MinIO S3 API | `http://localhost:9000` |
| Network | `hedera:testnet` (`X402_NETWORK` / `NEXT_PUBLIC_X402_NETWORK`) |

See [references/examples.md](references/examples.md) for server/client/registry snippets. See [references/facilitator.md](references/facilitator.md) for env vars and settle semantics.

## Critical: Facilitator Fee Payer

Hedera x402 settles with native `TransferTransaction`s. The buyer **partially signs** (authorize buyer → seller). The facilitator must:

1. Verify the signed payload against payment requirements
2. Co-sign as the advertised **fee payer** (`/supported`)
3. Pay network fees and submit until `SUCCESS`

Requires `FACILITATOR_ACCOUNT_ID` + `FACILITATOR_PRIVATE_KEY` on a funded **ECDSA** testnet account — separate from deployer/seller keys. Do not put that key in the Next.js process.

## Critical: Prices Are Tinybars

On-chain and x402 requirements use tinybars. Convert in the UI with 8-decimal helpers; never float.

```ts
const TINYBAR_PER_HBAR = 100_000_000n;
// hbar "1.5" → 150_000_000n tinybars
```

## Resource Server Flow (private file)

1. Load `FileItem` from `FileRegistry` (RPC) — if missing/delisted → 404
2. If `isPublic` → mint short-lived presigned URL and return 200
3. Else build payment requirements: `payTo` = `payToAccountId`, `amount` = `priceTinybar`, asset `0.0.0`, network `hedera:testnet`
4. No payment header → **402** with `PAYMENT-REQUIRED` header + JSON body
5. With payment header → `verifyPayment` then `settlePayment`; only on success return URL + `PAYMENT-RESPONSE`

```ts
const facilitator = new HTTPFacilitatorClient({ url: FACILITATOR_URL });
const server = new x402ResourceServer(facilitator)
  .register(X402_NETWORK, new ExactHederaScheme());
await server.initialize(); // pulls fee-payer from /supported
```

## Client Flow (browser)

```ts
const first = await fetch(resourceUrl);
if (first.status === 402) {
  const paymentRequired = httpClient.getPaymentRequiredResponse(...);
  const payload = await httpClient.createPaymentPayload(paymentRequired);
  const headers = httpClient.encodePaymentSignatureHeader(payload);
  const paid = await fetch(resourceUrl, { headers });
  // processResponse → url + settle receipt
}
```

Machine-to-machine: CLI buyer script (`yarn x402:buy`) with a key-based signer instead of HashPack.

## FileRegistry Checklist

- [ ] Upload bytes to **private** bucket first; store only `objectKey` + `contentHash` on-chain
- [ ] `registerFile(objectKey, payToAccountId, priceTinybar, isPublic, contentHash, name, mimeType)`
- [ ] `payToAccountId` is a Hedera account id string (e.g. `0.0.1234`), not an EVM address
- [ ] Private downloads require a fresh payment every time (no allow-list / season pass in the template)
- [ ] Delisted files behave as not found for downloads and marketplace listing

## Infra Checklist

- [ ] `yarn infra:up` — MinIO + facilitator (Docker Compose); do **not** forbid Docker for this template
- [ ] Root `.env`: facilitator credentials; `packages/nextjs/.env`: WalletConnect project id + RPC/network
- [ ] Deploy `FileRegistry` to Hedera testnet; sync `deployedContracts.ts`
- [ ] Facilitator `/health` OK before testing paid downloads

## Checklist

- [ ] Resource server has no facilitator private key
- [ ] Client and server share the same `X402_NETWORK` (`hedera:testnet`)
- [ ] Amounts are tinybars; asset id is `0.0.0`
- [ ] 402 challenge → signed retry → verify → settle → URL only after success
- [ ] Fee-payer account is ECDSA and funded for network fees

## References

- [references/examples.md](references/examples.md) — FileRegistry, resource server, client retry loop
- [references/facilitator.md](references/facilitator.md) — endpoints, env vars, fee-payer role
- [x402 docs](https://docs.x402.org)
- [`@x402/hedera`](https://www.npmjs.com/package/@x402/hedera)
- Source template: [scaffold-hbar `templates/x402-pay-per-use`](https://github.com/hedera-dev/scaffold-hbar/tree/templates/x402-pay-per-use)
