# Glossary

Use these terms exactly. Do not substitute "pack", "benchmark pack", or
"acceptance file" when a glossary word fits.

**Spec** — the coupled set of files the harness consumes for one benchmark
(PRD, **spec file**, static validator, command validator, and optionally
Playwright smoke + **oracle**). Layout is either **project** (preferred) or
**legacy clone**.
_Avoid_: pack, benchmark pack.

**Spec file** — the YAML the CLI loads: generator/validators/gates (and for
**project**, `extend.baseline`). Path is `.harness/spec.yaml` (**project**) or
`specs/<name>.yaml` (**legacy clone**). One file inside the **spec**.

**Slug** — the kebab-case name (`proof-wall`, `hcs-message-wall`) for the
**spec file** `name` field. In **project** layout, `templateMetadata.name` may
keep the host template identity and differ from the feature **slug**.

**Run** — the project-centric CLI command (`hedera-harness run`). Operates on
the project cwd (after `hedera-harness init` or an existing scaffolded app),
creates/continues `harness/run-*` branches, then generate → validate → repair.
Artifacts under `.harness/runs/`. Requires `extend.baseline` in project layout.

**Init** — bootstrap command (`hedera-harness init`) that seeds scaffold-hbar
into a directory, creates a **fresh git repo** (no scaffold history/remote),
and provisions `.harness/`.

**Project layout** — preferred in-place recipe under `.harness/` in a
scaffolded app. No seed. Spec lives under `.harness/`.

**Legacy clone** — historical greenfield layout under a harness clone
(`specs/<slug>.yaml`, `docs/prds/`, `validators/`). Prefer **project** for new
work.

**Blind** — the generation-integrity property. The PRD is vendored to the
generator; the **oracle** grades the running app. Pasting assertion ids,
`howToVerify`, or severity labels into the PRD destroys the property. Phrase
the rule as: **keep the run blind**.

**Oracle** — the acceptance contract JSON (`contracts/<name>-acceptance.json`
or `.harness/contracts/<slug>-acceptance.json`). Source of truth for semantic
pass/fail under gate 3. Grades numbered assertions — not the raw PRD.

**Gate** — a validation tier that can stop a run: 0–1 (deterministic), 2
(Playwright), 3 (semantic / **oracle**), 3.5 (on-chain). Every enabled **gate**
must pass.

**Needle** — a static text assertion (`textAssertions[].contains`) that pins a
string the generated template must document (e.g. `yarn next:dev`). Prefer
stable script names over incidental implementation detail.
