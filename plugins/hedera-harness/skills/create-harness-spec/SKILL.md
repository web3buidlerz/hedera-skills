---
name: create-harness-spec
description: Create a hedera-harness spec — PRD, spec file, validators, and optional gates — by grilling an idea into a runnable benchmark. Use when the user wants to turn a Hedera demo idea into harness inputs.
---

# Create Harness Spec

Grill a Hedera demo idea into a complete **spec** for
[hedera-harness](https://github.com/hedera-dev/hedera-harness).

Load the shared vocabulary first: read
[`../harness-spec-anatomy/SKILL.md`](../harness-spec-anatomy/SKILL.md) and its
[GLOSSARY.md](../harness-spec-anatomy/GLOSSARY.md). Use those terms exactly.

These skills are for authoring. The **spec file** `skills:` list carries
generator skills — name domain skills like `hedera-consensus-service`. Keep the
run **blind**: the PRD carries journeys and outcomes; the **oracle** lives in
the acceptance contract.

## Step 1: Locate the target and choose mode

Detect which layout to emit:

| Signal | Mode |
|--------|------|
| Cwd is a hedera-harness clone (`specs/`, `skeletons/new-template/`, `skills-index.json`) | **run** (greenfield) |
| Cwd is a scaffolded app with (or ready for) `.harness/` — e.g. Scaffold HBAR project, `packages/nextjs`, existing `.harness/spec.yaml` | **extend** (in-place) |
| Neither | Ask where to write and which mode |

**run:**

- Prefer copying skeletons from disk (always current).
- Without a clone: reconstruct gate 0–1 from
  `harness-spec-anatomy` → `references/spec-files.md`. For gates 2 / 3 / 3.5,
  fetch harness skeletons at the pinned ref in
  `harness-spec-anatomy` → `references/tier-strategy.md`.

**extend:**

- Emit under `.harness/` at the project root (see anatomy extend file table).
- Omit `seed`. Include `extend.baseline` with an `"install"`-named command.
- Set `templateMetadata.name` to the **host** template identity (often from
  existing app / package scripts), which may differ from the extension **slug**.

## Step 2: Grill

Follow [references/grilling.md](references/grilling.md). Prefer `/grilling` if
available; otherwise use the inline protocol there.

Decide **mode** (`run` vs **extend**) before slug / gates. Do **not** write
files until the user confirms shared understanding.

## Step 3: Emit the spec

### run (clone layout)

1. Pick the **slug**. Copy `skeletons/new-template/*` into the harness layout
   and rename `my-template` → slug (see the skeleton README for the `cp`/`sed`
   one-liner). Without a clone, reconstruct from
   `harness-spec-anatomy` → `references/spec-files.md`.
2. Fill gate 0–1: PRD, **spec file**, static validator, yarn validator. Keep
   gates 2 / 3 / 3.5 commented unless the user asked for them.
3. Set `skills:` to generator skill names from `skills-index.json` that match
   the Hedera services chosen in the grill.
4. Optionally deepen (gates 2 / 3 / 3.5) per
   `harness-spec-anatomy` → `references/tier-strategy.md`.

### extend (`.harness/` layout)

1. Pick the extension **slug**. Write `.harness/prd.md`, `.harness/spec.yaml`,
   `.harness/validators/static.json`, `.harness/validators/yarn.json` using the
   extend compact body in `references/spec-files.md`.
2. No `seed`. Include `extend.baseline` (install / lint / build against the
   host app). Point validators at `.harness/...` paths.
3. Set `skills:` from a local or remote `skills-index.json` (harness package /
   clone) that match the services chosen in the grill.
4. Optionally deepen into `.harness/playwright/` and `.harness/contracts/`.

## Step 4: Completion criterion

Run the anatomy script (resolve path relative to the installed skill):

```bash
bash <path-to>/harness-spec-anatomy/scripts/check-spec.sh <root> <slug>
```

Use the harness clone root for **run**, or the scaffolded project root for
**extend**.

**Done when `check-spec.sh` exits clean.** If the script is missing, fall back
to the slug map and **blind** rules in `harness-spec-anatomy` by hand.

Then hand off:

```bash
# Prefer /review-harness-spec next, then:

# run (clone):
npm run harness -- run specs/<slug>.yaml --max-attempts 3

# extend (scaffolded project):
yarn harness:extend
# or: hedera-harness extend .harness/spec.yaml --max-attempts 3
```

Point at the harness README for install, `agent` auth, and gate host
prerequisites. Do not expand CLI teaching beyond these next commands.

## Additional resources

- [references/grilling.md](references/grilling.md)
- Companion: `/review-harness-spec`
- Vocabulary: `/harness-spec-anatomy`
