# Review checklist

Work top to bottom. Mark each item pass / fail / n/a.

## A. Identity and paths

- [ ] **A1** `spec.name` === `templateMetadata.name`
- [ ] **A2** Static JSON assertion on `template.json` `name` equals `spec.name`
- [ ] **A3** If contract exists: `contract.template` === `spec.name`; contract `name` is coherent (e.g. `<name>-acceptance`)
- [ ] **A4** `spec.prd` file exists on disk
- [ ] **A5** If contract exists: `contract.prd` points at the same path as `spec.prd`
- [ ] **A6** `validators.static` and `validators.commands` files exist; paths match the slug
- [ ] **A7** If Playwright enabled: smoke file exists and `name` matches slug convention

## B. Cross-file consistency

- [ ] **B1** `spec.forbiddenFiles` agrees with `static.fileAssertions.forbidden` (same set, or document intentional extras)
- [ ] **B2** `constraints.packageManager` matches the static assertion on `package.json` `packageManager`
- [ ] **B3** Contract `routes` (if present) and Playwright `routes` (if present) are consistent with each other and with PRD deliverable routes
- [ ] **B4** Static `textAssertions` needles match scripts the PRD / template will actually document (`yarn install`, `yarn next:dev`, …) — not brittle implementation strings
- [ ] **B5** If Solidity is a non-goal: `forbiddenWorkspaces` / forbidden Hardhat paths align with the PRD; if Solidity is in scope: do not forbid the needed workspaces

## C. Command validator

- [ ] **C1** Commands JSON has a command with `"name": "install"` (load-bearing for fingerprint skip)
- [ ] **C2** `requiresNoSecrets: true` (or equivalent — no commands that need live operator keys)
- [ ] **C3** Timeouts are generous enough for cold CI (install ≥ 300s typical)
- [ ] **C4** `forbiddenCommands` blocks npm/pnpm when the template is Yarn-based

## D. Tier prerequisites

- [ ] **D1** Tier 0–1: both `validators.static` and `validators.commands` set
- [ ] **D2** Tier 2: `validators.playwright` uncommented **and** smoke file filled (no leftover `REPLACE_ME` routes)
- [ ] **D3** Tier 3: **both** `contract:` path **and** `validator.enabled: true` present — one without the other is a blocker
- [ ] **D4** Tier 3.5: `chainValidation.enabled: true`, `network: testnet` (mainnet rejected by loader), operator env var names set; Tier 3 must also be on
- [ ] **D5** Any assertion with `executableWithTestSigner: true` requires Tier 3.5 enabled — otherwise those assertions are inert (warning if marked without `chainValidation`)
- [ ] **D6** Spec `skills:` (if any) lists **generator** skills from `skills-index.json` only — never `harness-spec-author` / `harness-spec-review`

## E. Severity budget and Playwright thinness

- [ ] **E1** Prefer ≤ 2 `critical` assertions; flag packs where most assertions are `critical`
- [ ] **E2** Playwright stays thin (server + routes + forbidden crash text); deep UX belongs in the contract
- [ ] **E3** Contract assertions have stable ids (`C1`, `C2`, …), non-empty `statement` and `howToVerify`, and no leftover `REPLACE_ME`

## F. Oracle integrity

- [ ] **F1** PRD does **not** contain assertion ids (`C1`, …), `howToVerify` scripts, severity labels, or mirror verification recipes copied from the contract
- [ ] **F2** PRD stays product-facing (Goal / Journeys / Services / Non-goals / Deliverables); Acceptance section points at the contract rather than duplicating it
- [ ] **F3** If contract exists: `evaluationRules.failOnUncertainty` (or equivalent fail-closed posture) is present — absence of evidence must fail

## G. Secrets and seed

- [ ] **G1** No real private keys or account ids in any pack file
- [ ] **G2** `secretScan` / forbidden `.env` paths present for scaffold-hbar templates
- [ ] **G3** `seed.repo` / `seed.ref` sensible (public scaffold-hbar default is fine)
- [ ] **G4** `isolation.neverModifySeedRepo: true` (or equivalent) when using a shared seed

## Quick blocker shortlist

Fail the review as not-runnable if any of these fail: **A1–A5**, **C1**, **D3** (when Tier 3 intended), **D4** `network` (when 3.5 intended), **F1**.
