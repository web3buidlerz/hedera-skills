# Glossary

Use these terms exactly. Do not substitute "pack", "benchmark pack", or
"acceptance file" when a glossary word fits.

**Spec** — the coupled set of files the harness consumes for one benchmark
(PRD, **spec file**, static validator, command validator, and optionally
Playwright smoke + **oracle**). Layout is either clone/`run` or **extend**.
_Avoid_: pack, benchmark pack.

**Spec file** — the YAML the CLI loads: seed/generator/validators/gates (and
for **extend**, `extend.baseline`). Path is `specs/<name>.yaml` (clone / `run`)
or `.harness/spec.yaml` (**extend**). One file inside the **spec**.

**Slug** — the kebab-case name (`proof-wall`, `hedera-demo-extend`) for the
**spec file** `name` field and classic path map. In **extend** layout,
`templateMetadata.name` may keep the host template identity and differ from
the extension **slug**.

**Run** — greenfield CLI mode (`hedera-harness run`). Seeds an isolated
workspace from `scaffold-hbar`, then generate → validate → repair. Artifacts
under `runs/`.

**Extend** — in-place CLI mode (`hedera-harness extend`). No seed; the
scaffolded project cwd is the workspace. Spec lives under `.harness/`.
Artifacts under `.harness/runs/`. Requires `extend.baseline`.

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
