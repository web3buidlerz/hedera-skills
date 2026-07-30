---
name: harness-spec-review
description: >-
  Audit an existing hedera-harness benchmark pack for cross-file inconsistencies,
  tier misconfiguration, severity budget issues, and oracle-integrity problems
  before a run. Use when the user asks to review a harness spec, check a
  benchmark pack, validate harness inputs, audit an acceptance contract, or
  confirm a PRD/spec/validators pack is ready to run.
---

# Harness Spec Review

Audit a hedera-harness **benchmark pack** on disk and report findings by
severity. Catch mistakes the harness only surfaces after a generator attempt
is already burning.

**Authoring-only skill.** Do not add this skill to a template spec's `skills:`
list. It is for humans/agents reviewing packs before `harness run`.

## Step 1: Locate the pack

Ask for the slug (or infer from open files). Resolve these paths relative to
the harness clone root (or the user-chosen pack root):

| Artifact | Path |
|----------|------|
| Spec | `specs/<name>.yaml` |
| PRD | path in `spec.prd` (usually `docs/prds/<name>.md`) |
| Static | `spec.validators.static` |
| Commands | `spec.validators.commands` |
| Playwright | `spec.validators.playwright` if uncommented / present |
| Contract | `spec.contract` if uncommented / present |

Read every file that exists. If the spec is missing, stop and ask.

## Step 2: Run the checklist

Work through [references/review-checklist.md](references/review-checklist.md).
For each check: **pass**, **fail**, or **n/a** (tier not enabled). Cite the
exact fields/paths that disagree.

## Step 3: Emit the report

```markdown
# Harness Pack Review — <name>

## Summary
- **Tier ambition**: 0–1 | +2 | +3 | +3.5
- **Ready to run Tier 0–1?**: yes / no
- **Blockers**: N
- **Warnings**: N

## Findings

### 🔴 Blocker
- [id] <what> — <where> — <fix>

### 🟡 Warning
- [id] <what> — <where> — <fix>

### 🟢 OK
- Short list of important checks that passed

## Suggested next commands
```bash
npm run harness -- validate specs/<name>.yaml --workspace runs/<id>/workspace
# or, when Tier 0–1 looks solid:
npm run harness -- run specs/<name>.yaml --max-attempts 3
```
```

## Severity rules

| Level | Use when |
|-------|----------|
| **Blocker** | Cross-file name/path disagreement; missing `install` command name; Tier 3 missing `contract` or `validator.enabled`; contract text pasted into PRD; `chainValidation.network` not `testnet` |
| **Warning** | Too many `critical` assertions; Playwright too thick; static needles too brittle; `executableWithTestSigner` without `chainValidation`; skills list includes authoring skills |
| **OK** | Consistent names, fail-closed `evaluationRules`, thin Playwright, PRD product-facing |

Be constructive: every finding needs a concrete fix. Prefer fixing blockers
before suggesting a full `run`.

## Additional resources

- [review-checklist.md](references/review-checklist.md)
- Companion author skill: `harness-spec-author` (same plugin)
