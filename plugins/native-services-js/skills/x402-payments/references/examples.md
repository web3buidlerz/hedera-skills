# x402 Pay-Per-Use Examples

Condensed patterns from Scaffold-HBAR `templates/x402-pay-per-use`. Prefer the template for production copy-paste.

## FileRegistry (on-chain terms)

```solidity
string public constant PAYMENT_ASSET = "0.0.0"; // native HBAR; prices in tinybars

struct FileItem {
    address owner;
    string payToAccountId;   // e.g. "0.0.1234"
    uint256 priceTinybar;
    bool isPublic;
    string objectKey;        // private bucket key — not file bytes
    bytes32 contentHash;     // SHA-256
    string name;
    string mimeType;
    bool exists;
}

function registerFile(
    string calldata objectKey,
    string calldata payToAccountId,
    uint256 priceTinybar,
    bool isPublic,
    bytes32 contentHash,
    string calldata name,
    string calldata mimeType
) external returns (bytes32 fileId);
```

Access control for downloads is **off-chain**: the resource server reads these fields and decides free vs 402.

## Resource server wiring

```ts
import { HTTPFacilitatorClient, x402ResourceServer } from "@x402/core/server";
import { ExactHederaScheme } from "@x402/hedera/exact/server";

const facilitator = new HTTPFacilitatorClient({
  url: process.env.FACILITATOR_URL ?? "http://localhost:4020",
});
const server = new x402ResourceServer(facilitator).register(
  (process.env.X402_NETWORK ?? "hedera:testnet") as Network,
  new ExactHederaScheme(),
);
await server.initialize();
```

Payment header (v2 or legacy):

```ts
paymentHeader:
  req.headers.get("payment-signature") ??
  req.headers.get("x-payment") ??
  undefined;
```

## Download route sketch (private)

```ts
// 1) No payment → 402 challenge
const paymentRequiredBody = await server.buildPaymentRequiredResponse(...);
const res = NextResponse.json(paymentRequiredBody, { status: 402 });
res.headers.set("PAYMENT-REQUIRED", encodePaymentRequiredHeader(paymentRequiredBody));

// 2) With payment → verify then settle; URL only after success
const verification = await server.verifyPayment(payload, matched);
const settlement = await server.settlePayment(payload, matched);
if (!settlement.success) {
  return NextResponse.json({ error: "Payment settlement failed" }, { status: 402 });
}
const response = NextResponse.json({ url: presignedUrl });
response.headers.set("PAYMENT-RESPONSE", encodePaymentResponseHeader(settlement));
```

## Browser client retry loop

```ts
const httpClient = new x402HTTPClient(
  new x402Client().register(network, new ExactHederaScheme(signer)),
);

const first = await fetch(resourceUrl);
if (first.status === 402) {
  const paymentRequired = httpClient.getPaymentRequiredResponse(
    name => first.headers.get(name),
    await first.clone().json().catch(() => undefined),
  );
  const payload = await httpClient.createPaymentPayload(paymentRequired);
  const headers = httpClient.encodePaymentSignatureHeader(payload);
  const paid = await fetch(resourceUrl, { headers });
  const result = await httpClient.processResponse(paid);
  // result.kind === "success" → body.url
}
```

Signer builds a native HBAR transfer: debit buyer, credit `requirements.payTo`, amount in tinybars.

## Tinybar helpers

```ts
export const TINYBAR_PER_HBAR = 100_000_000n;

export function hbarToTinybar(hbar: string): bigint {
  const [whole = "0", fraction = ""] = hbar.trim().split(".");
  if (fraction.length > 8) throw new Error("HBAR supports at most 8 decimal places");
  return BigInt(whole || "0") * TINYBAR_PER_HBAR + BigInt(fraction.padEnd(8, "0") || "0");
}
```

## Deploy + infra order (template)

```text
1. yarn install
2. Root .env — FACILITATOR_ACCOUNT_ID / FACILITATOR_PRIVATE_KEY (ECDSA, funded)
3. packages/nextjs/.env — WalletConnect project id
4. yarn hardhat:deploy --network hederaTestnet  # FileRegistry
5. yarn infra:up                                 # MinIO + facilitator
6. yarn next:dev                                 # upload / pay / download
7. Optional: yarn x402:buy                       # CLI buyer
```
