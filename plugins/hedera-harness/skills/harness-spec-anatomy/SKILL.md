---
name: harness-spec-anatomy
description: Shared vocabulary for hedera-harness specs — the files, the slug map, the gates, and the blind/oracle rule. Use when authoring or auditing a harness spec, or when another skill needs the spec vocabulary.
---

# Harness Spec Anatomy

Single source of truth for what a hedera-harness **spec** is. Action skills
(`/create-harness-spec`, `/review-harness-spec`) reach here for vocabulary;
they own workflow. Use the bold terms from [GLOSSARY.md](GLOSSARY.md) exactly.

**These skills are for authoring — not for generator runs.** The `skills:` list
in a **spec file** carries generator skills (domain knowledge for the coding
agent). Name skills like `hedera-consensus-service`, `hts-system-contract`,
`project-scaffolding`. Keep authoring skills out of that list.

## Layouts

A **spec** is the same six coupled concepts in either layout. Paths differ.

### Clone / `run` (greenfield)

Harness clone root. Seeds a fresh workspace from `scaffold-hbar`.

| File | Required? | Consumed by |
|------|-----------|-------------|
| `docs/prds/<name>.md` | Yes | Generator (vendored into workspace) |
| `specs/<name>.yaml` (**spec file**) | Yes | Harness CLI (`run` / `validate` / `validate-semantic`) |
| `validators/<name>-static.json` | Yes | Gate 0–1 static validator |
| `validators/<name>-yarn.json` | Yes | Gate 0–1 command validator |
| `playwright/<name>-smoke.yaml` | Gate 2 | Playwright gate |
| `contracts/<name>-acceptance.json` | Gate 3 | Semantic validator (**oracle**) |

Artifacts: `runs/`. Handoff: `hedera-harness run specs/<slug>.yaml`.

### Extend / in-place (scaffolded project)

Already-scaffolded app root (parent of `.harness/`). **No seed** — the
workspace is the project itself. Paths in the **spec file** are relative to
that project root.

| File | Required? | Consumed by |
|------|-----------|-------------|
| `.harness/prd.md` | Yes | Generator |
| `.harness/spec.yaml` (**spec file**) | Yes | Harness CLI (`extend` / `validate` / `validate-semantic`) |
| `.harness/validators/static.json` | Yes | Gate 0–1 static validator |
| `.harness/validators/yarn.json` | Yes | Gate 0–1 command validator |
| `.harness/playwright/<slug>-smoke.yaml` | Gate 2 | Playwright gate |
| `.harness/contracts/<slug>-acceptance.json` | Gate 3 | Semantic validator (**oracle**) |

Also required in the **spec file**: `extend.baseline` (commands that prove the
host app is healthy before the extension). Artifacts: `.harness/runs/`.
Handoff: `yarn harness:extend` or `hedera-harness extend .harness/spec.yaml`.

Compact Tier 0–1 bodies and reconstruction notes: [references/spec-files.md](references/spec-files.md).

## Slug map

These must all agree on the same **slug** (`<name>`) in **clone / `run`**
layout:

| Location | Field |
|----------|-------|
| Spec file | `name` |
| Spec file | `templateMetadata.name` |
| Spec file | `prd: docs/prds/<name>.md` |
| Spec file | `validators.static` / `validators.commands` paths |
| Static JSON | `jsonAssertions` → `template.json` → `name` equals `<name>` |
| Oracle (if present) | `name`, `template`, `prd` |
| Playwright (if present) | `name` (e.g. `<name>-smoke`) |

**Extend layout differences:**

- Spec file `name` is the extension slug (e.g. `hedera-demo-extend`)
- `templateMetadata.name` is the **existing** template identity (e.g. `hedera-demo`) — it may differ from the extension slug
- PRD / validator filenames often omit the slug (`.harness/prd.md`, `.harness/validators/static.json`)
- Static validators usually assert app scripts / package fields, not `template.json` name (create-scaffold-hbar removes `template.json`)

Also keep in sync (both layouts):

- Spec file `forbiddenFiles` ↔ static `fileAssertions.forbidden`
- `constraints.packageManager` ↔ static assertion on `package.json` `packageManager`
- Oracle `routes` ↔ Playwright `routes` ↔ PRD deliverable routes

## Gates

Enable in order. Skeleton default is **gate 0–1 only**. Gate enablement is
identical for `run` and `extend`; only copy targets and CLI commands differ.

| Gate | Spec file fields | What it checks |
|------|------------------|----------------|
| **0–1** | `validators.static`, `validators.commands`, `requiredFiles`, `forbiddenFiles`, `secretScan` | Files, JSON/text, secrets, yarn install/lint/build |
| **2** | `validators.playwright` | Dev server boots; routes HTTP OK; console / forbidden text |
| **3** | `contract` + `validator` | Semantic agent grades numbered assertions in the **oracle** |
| **3.5** | `chainValidation` (+ gate 3) | Ephemeral ECDSA test signer; real txs; mirror verify |

Full enable order, host prerequisites, and uncommented YAML blocks:
[references/tier-strategy.md](references/tier-strategy.md).

## Blind / oracle rule

Keep the run **blind**. The PRD carries journeys and outcomes; the **oracle**
lives in the acceptance contract. See [GLOSSARY.md](GLOSSARY.md) and
[references/prd-and-journeys.md](references/prd-and-journeys.md).

## Drift-sensitive loader fields

When the harness renames these, update this skill and its evals in the same
change set:

`prd`, `seed`, `generator`, `validators.static`, `validators.commands`,
`validators.playwright`, `templateMetadata`, `requiredFiles`, `forbiddenFiles`,
`secretScan`, `contract`, `validator`, `chainValidation`, `skills`,
`executableWithTestSigner`, `maxAttempts`, `extend`, `extend.baseline`.

## Mechanical check

```bash
# Clone / run layout:
bash skills/harness-spec-anatomy/scripts/check-spec.sh <harness-root> <slug>

# Extend layout (project root that contains .harness/):
bash skills/harness-spec-anatomy/scripts/check-spec.sh <project-root> <slug>
```

Resolve the script path relative to the installed skill. Exit zero means wiring
is clean; non-zero prints one finding per line. If the script is missing, fall
back to the slug map and gate rules by hand.

## Additional resources

- [GLOSSARY.md](GLOSSARY.md)
- [references/spec-files.md](references/spec-files.md)
- [references/prd-and-journeys.md](references/prd-and-journeys.md)
- [references/acceptance-contract-guide.md](references/acceptance-contract-guide.md)
- [references/tier-strategy.md](references/tier-strategy.md)
- [scripts/check-spec.sh](scripts/check-spec.sh)
