# PRD and journeys

The PRD is the product brief the **generator** sees. Keep it product-facing.
Numbered, browser-verifiable pass/fail rules live only in the acceptance
contract — never in this document.

## Oracle integrity (non-negotiable)

| Allowed in the PRD | Forbidden in the PRD |
|--------------------|----------------------|
| Goal, journeys, services, non-goals, deliverables | Assertion ids (`C1`, `C2`, …) |
| Route names at a product level (`/`, `/feed`) | `howToVerify` browser scripts |
| "Wallet-gated: post a message" as a journey | `severity: critical` / grading language |
| Empty-state and testnet expectations | Mirror-node verification recipes |

The harness vendors the PRD into the workspace and grades against the contract.
Pasting contract text into the PRD destroys blind generation.

## Required sections

Use this structure (matches the harness skeleton):

```markdown
# <Title> (PRD)

## Goal
One paragraph: what Hedera demo this template ships, who it is for, and what
"done" looks like in a browser without live credentials.

## Journeys
1. **Browse without a wallet** — what the user can see/do read-only.
2. **Configure / admin (if any)** — setup UI; what requires a wallet.
3. **Wallet-gated actions** — name the affordances; do not require a successful
   on-chain tx for acceptance at Tier 0–3 (unless Tier 3.5 is planned).

## Hedera services
- List services (HCS, HTS, …) and how they appear in the UI.
- Default network (usually testnet) and empty-state behavior when nothing is configured.

## Non-goals
- No live operator keys or `.env` required to open the app.
- Call out frameworks you forbid (e.g. Hardhat/Foundry) if this is native/services-only.

## Deliverables
- `template.json`, `README.md`, `AGENTS.md` suitable for scaffold-hbar
- Yarn workspace layout and scripts (`yarn install`, `yarn next:dev`, …)
- Routes the acceptance contract will visit (names only — not verification steps)

## Acceptance
Numbered, browser-verifiable assertions live in the **acceptance contract** JSON —
not only in this PRD. Keep this document product-facing; keep the contract test-facing.
```

## Splitting read path vs wallet-gated

Ask: *Can a stranger open the app with no wallet and no `.env` and still see something useful?*

| Path | Examples | Contract posture |
|------|----------|------------------|
| Read / browse | Home copy, network label, empty feed, docs links | `walletRequired: false`, `verifiableWithoutCredentials: true` |
| Affordance | Connect button, "needs wallet" messaging, disabled submit | `walletRequired: true`, still verifiable without credentials |
| Write / on-chain | Submit HCS message, mint, contract call | Only with Tier 3.5 + `executableWithTestSigner: true` |

Design the PRD so the first journey is always a solid credential-free browse path.
Wallet flows describe affordances; they do not require a funded account for the
demo to be "done" unless the user explicitly wants Tier 3.5.

## Journey → contract mapping (later)

When deepening to Tier 3, each PRD journey should produce 1–3 assertions:

| Journey | Typical assertions |
|---------|-------------------|
| Browse without wallet | `C1` critical home load; `C2` major read capability |
| Wallet-gated action | Affordance + clear messaging without connecting |
| On-chain (optional) | `executableWithTestSigner` only if `chainValidation` is enabled |

See [acceptance-contract-guide.md](acceptance-contract-guide.md).
