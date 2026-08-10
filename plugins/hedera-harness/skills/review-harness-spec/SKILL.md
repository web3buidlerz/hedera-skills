---
name: review-harness-spec
description: Audit an existing hedera-harness spec for wiring and oracle problems before a run. Use when the user wants a harness spec reviewed before running it.
---

# Review Harness Spec

Audit a hedera-harness **spec** on disk along two axes. Catch mistakes the
harness only surfaces after a generator attempt is already burning.

Load the shared vocabulary first: read
[`../harness-spec-anatomy/SKILL.md`](../harness-spec-anatomy/SKILL.md) and its
[GLOSSARY.md](../harness-spec-anatomy/GLOSSARY.md).

Authoring-only skill. The **spec file** `skills:` list carries generator skills.

## Step 1: Locate the spec

Ask for the **slug** (or infer from open files). Detect layout:

- **project (preferred):** `.harness/spec.yaml` under a scaffolded project root
  (`name:` must match the slug)
- **legacy clone:** `specs/<slug>.yaml` under a harness clone root

Resolve paths using the file tables in `harness-spec-anatomy`. Read every file
that exists. If the **spec file** is missing, stop and ask.

## Step 2: Wiring axis

Run the anatomy script (resolve path relative to the installed skill):

```bash
bash <path-to>/harness-spec-anatomy/scripts/check-spec.sh <root> <slug>
```

`<root>` is the project root that contains `.harness/` (project) or the harness
clone (legacy clone).

Report its findings **verbatim** under `## Wiring`. If the script is missing,
fall back to the slug map, gate pairing rules, and **blind** checks in
`harness-spec-anatomy` by hand — still under `## Wiring`.

## Step 3: Oracle axis

Judgment only — what a script cannot see. Work through
[references/review-checklist.md](references/review-checklist.md). Cover at least:

- Every PRD journey maps to ≥ 1 **oracle** assertion
- Every assertion traces back to a PRD journey (no orphans / scope creep)
- Severity budget sane (prefer ≤ 2 `critical`)
- **Needles** pin real yarn scripts, not brittle implementation strings
- Playwright **gate** stays thin; deep UX lives in the **oracle**
- Generator `skills:` list is appropriate (no authoring skills)
- For **project** layout: no seed / isolation assumptions; `extend.baseline`
  present; `requiredFiles` include `.harness/*` when appropriate

Report under `## Oracle`. Do **not** merge or rerank with Wiring — a **spec**
can be perfectly wired and still grade the wrong thing.

## Step 4: Emit the report

```markdown
# Harness Spec Review — <slug>

## Summary
- **Layout**: project | legacy-clone
- **Gate ambition**: 0–1 | +2 | +3 | +3.5
- **Ready to run gate 0–1?**: yes / no
- **Wiring findings**: N
- **Oracle findings**: N

## Wiring
- [script output or hand-checked findings]

## Oracle
### Blocker
- [id] <what> — <where> — <fix>
### Warning
- [id] <what> — <where> — <fix>
### OK
- [id] <what>
```

## Step 5: Handoff

If ready for gate 0–1:

```bash
# project:
hedera-harness run .harness/spec.yaml --max-attempts 3

# legacy clone:
hedera-harness run specs/<slug>.yaml --max-attempts 3
```

## Additional resources

- [references/review-checklist.md](references/review-checklist.md)
- Companion: `/create-harness-spec`
- Vocabulary: `/harness-spec-anatomy`
