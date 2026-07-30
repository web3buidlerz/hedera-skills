# Tier strategy

Enable tiers in order. The skeleton defaults to **Tier 0–1 only** so the first
run stays cheap. Uncomment higher tiers only after lower ones are green.

Pinned skeleton source (prefer a local harness clone when present):

- Repo: https://github.com/hedera-dev/hedera-harness
- Ref: `main`
- Directory: `skeletons/new-template/`

Raw stubs:

- [playwright-smoke.yaml](https://raw.githubusercontent.com/hedera-dev/hedera-harness/main/skeletons/new-template/playwright-smoke.yaml)
- [acceptance-contract.json](https://raw.githubusercontent.com/hedera-dev/hedera-harness/main/skeletons/new-template/acceptance-contract.json)
- [spec.yaml](https://raw.githubusercontent.com/hedera-dev/hedera-harness/main/skeletons/new-template/spec.yaml) (commented Tier 2 / 3 / 3.5 blocks)

Authoring checklist in the harness repo:
[docs/authoring-a-template.md](https://github.com/hedera-dev/hedera-harness/blob/main/docs/authoring-a-template.md)

## Enable order

| Tier | Spec fields | What it checks | Host prerequisites |
|------|-------------|----------------|--------------------|
| **0–1** | `validators.static`, `validators.commands`, `requiredFiles`, `forbiddenFiles`, `secretScan` | Files, JSON/text, secrets, yarn install/lint/build | Node ≥ 20, yarn, `agent` on PATH |
| **2** | `validators.playwright` | Dev server boots; routes HTTP OK; console / forbidden text | `npx playwright install chromium` |
| **3** | `contract` + `validator` | Semantic agent grades numbered assertions | Playwright MCP usable headless; validator flags `--force`, `--sandbox disabled`, `--approve-mcps` |
| **3.5** | `chainValidation` (+ Tier 3) | Ephemeral ECDSA test signer; real txs; mirror verify | Funded **ECDSA** testnet operator; `HEDERA_OPERATOR_ID` / `HEDERA_OPERATOR_KEY` in the shell |

Pass condition: every enabled tier must pass. Semantic **infra** failures
(MCP / browser missing) **abort** the repair loop — they are not app bugs.

## Tier 2 — thin Playwright smoke

Copy `skeletons/new-template/playwright-smoke.yaml` → `playwright/<name>-smoke.yaml`.

Rules:

- `server.command` / `server.url` match how the template starts (often `yarn next:dev` / `http://localhost:3000`)
- One entry per critical route
- `forbidden.visibleText` for crash banners
- Keep thin — rich UX checks belong in the acceptance contract
- Extra YAML `assertions` blocks are documentation for humans / future use; the
  harness gate currently enforces: server up, route HTTP success, console errors
  (if enabled), and forbidden visible text

In the spec, uncomment:

```yaml
validators:
  playwright: playwright/<name>-smoke.yaml
```

## Tier 3 — semantic contract + validator agent

1. Fill `contracts/<name>-acceptance.json` (see [acceptance-contract-guide.md](acceptance-contract-guide.md)).
2. Uncomment both in the spec:

```yaml
contract: contracts/<name>-acceptance.json

validator:
  enabled: true
  provider: command
  command: agent
  args:
    - -p
    - --trust
    - --force
    - --sandbox
    - disabled
    - --approve-mcps
    - --workspace
    - "{workspace}"
    - --model
    - composer-2.5
    - --output-format
    - stream-json
    - --stream-partial-output
  timeoutMs: 600000
```

Both `contract` and `validator.enabled: true` are required. One without the
other is a misconfigured pack.

## Tier 3.5 — on-chain (advanced, opt-in)

Only when the user wants real transactions graded. Requires Tier 3.

```yaml
chainValidation:
  enabled: true
  network: testnet            # mainnet is rejected by the loader
  operator:
    accountIdEnv: HEDERA_OPERATOR_ID
    privateKeyEnv: HEDERA_OPERATOR_KEY
  fundingHbar: 10
  sweepBack: true
  expose:
    browserLocalStorageKey: burnerWallet.pk
    envVars: []
```

Checklist:

- Host has a funded **ECDSA** testnet operator (not ED25519)
- Env vars exported in the shell — never written into the workspace
- Contract assertions that need a real tx set `executableWithTestSigner: true`
- Template keeps the burner connector enabled so headless signing works
- For Solidity: optional `deploy.commands` + `expose.envVars` before grading

`executableWithTestSigner` assertions are **inert** unless `chainValidation`
is enabled — do not mark them executable "for later" without enabling the block.

## Smoke before a full run

```bash
npm run harness -- validate specs/<name>.yaml --workspace runs/<id>/workspace
npm run harness -- validate-semantic specs/<name>.yaml --workspace runs/<id>/workspace
npm run harness -- run specs/<name>.yaml --max-attempts 3
```

Prefer `harness-spec-review` on the pack before burning generator attempts.
