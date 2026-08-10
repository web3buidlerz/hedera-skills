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

## Step 1: Locate the target

**Default / preferred layout is project-centric** (`.harness/` in a scaffolded app):

| Signal | Layout |
|--------|--------|
| Cwd is a scaffolded app (Scaffold HBAR / `hedera-harness init` project) with or ready for `.harness/` | **project** (primary) |
| Cwd is a hedera-harness clone (`specs/`, `skeletons/new-template/`) | **legacy clone** (historical greenfield only) |
| Neither | Ask where to write; prefer **project** |

**project (primary):**

- Bootstrap with `hedera-harness init <dir>` if the app does not exist yet.
- Emit under `.harness/` at the project root (see anatomy project file table).
- Omit `seed`. Include `extend.baseline` with an `"install"`-named command
  (YAML key name is historical; used by `hedera-harness run`).
- Paths in the **spec file** are relative to the project root.

**legacy clone (optional):**

- Prefer copying `skeletons/new-template/*` from a harness clone.
- Without a clone: reconstruct gate 0–1 from
  `harness-spec-anatomy` → `references/spec-files.md`.

## Step 2: Grill

Follow [references/grilling.md](references/grilling.md). Prefer `/grilling` if
available; otherwise use the inline protocol there.

Confirm **project** layout (or legacy clone) before slug / gates. Do **not**
write files until the user confirms shared understanding.

## Step 3: Emit the spec

### project (`.harness/` layout) — preferred

1. Pick the feature **slug**. Write `.harness/prd.md`, `.harness/spec.yaml`,
   `.harness/validators/static.json`, `.harness/validators/yarn.json` using the
   project compact body in `references/spec-files.md`.
2. No `seed`. Include `extend.baseline` (install / lint / build against the
   host app). Point validators at `.harness/...` paths.
3. Set `skills:` from a local or remote `skills-index.json` (harness package)
   that match the services chosen in the grill.
4. Optionally deepen into `.harness/playwright/` and `.harness/contracts/`.

### legacy clone (`specs/<slug>.yaml`)

1. Pick the **slug**. Copy `skeletons/new-template/*` and rename `my-template`
   → slug. Without a clone, reconstruct from
   `harness-spec-anatomy` → `references/spec-files.md`.
2. Fill gate 0–1; keep gates 2 / 3 / 3.5 commented unless requested.
3. Set `skills:` from `skills-index.json`.

## Step 4: Completion criterion

Run the anatomy script (resolve path relative to the installed skill):

```bash
bash <path-to>/harness-spec-anatomy/scripts/check-spec.sh <root> <slug>
```

Use the scaffolded project root for **project**, or the harness clone root for
**legacy clone**.

**Done when `check-spec.sh` exits clean.** If the script is missing, fall back
to the slug map and **blind** rules in `harness-spec-anatomy` by hand.

Then hand off:

```bash
# Prefer /review-harness-spec next, then:

# project (preferred):
hedera-harness run .harness/spec.yaml --max-attempts 3
# or: yarn harness:run

# legacy clone only:
hedera-harness run specs/<slug>.yaml --max-attempts 3
```

Point at the harness README for install, `agent` auth, and gate host
prerequisites. Do not expand CLI teaching beyond these next commands.

## Additional resources

- [references/grilling.md](references/grilling.md)
- Companion: `/review-harness-spec`
- Vocabulary: `/harness-spec-anatomy`
