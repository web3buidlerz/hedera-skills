# Hedera Harness

Agent skills for **creating and reviewing** [hedera-harness](https://github.com/hedera-dev/hedera-harness) specs — PRD, spec file, validators, Playwright smoke, and acceptance contracts (oracle) that drive Scaffold HBAR template generation **or** in-place **extend** of an already-scaffolded app.

These skills are for the human or agent writing the **spec** **before** a run / extend. They are **not** generator skills: do not list them in a template **spec file**'s `skills:` field (that list is vendored into the workspace for the coding agent that builds the demo).

## Installation

### Claude Code

```bash
# Step 1: Add the Hedera marketplace (skip if already added)
/plugin marketplace add hedera-dev/hedera-skills

# Step 2: Install the plugin
/plugin install hedera-harness
```

### Other Agents (npx skills)

```bash
npx skills add hedera-dev/hedera-skills
```

## Skills

| Skill | Purpose |
|-------|---------|
| `harness-spec-anatomy` | Shared vocabulary + dual layouts (`run` / **extend**) + `check-spec.sh` |
| `create-harness-spec` | Grill an idea → emit a runnable **spec** (clone or `.harness/`) |
| `review-harness-spec` | Two-axis audit (Wiring + Oracle) before `harness run` / `extend` |

### harness-spec-anatomy

Model-invoked vocabulary layer. Defines **spec**, **spec file**, **slug**,
**run**, **extend**, **blind**, **oracle**, **gate**, and **needle**. Houses
the mechanical checker (auto-detects clone vs `.harness/` layout):

```bash
bash skills/harness-spec-anatomy/scripts/check-spec.sh <root> <slug>
```

### create-harness-spec

Triggers when you say: "create a harness spec", "turn this demo into harness inputs", "author a hedera-harness PRD", "add an extend recipe under .harness".

**Provides:**

- Detect **run** (harness clone) vs **extend** (scaffolded app)
- Hybrid grilling (prefer `/grilling` when installed; else inline one-question-at-a-time protocol)
- Dependency-ordered decision tree (mode → slug → Solidity → skills → gates)
- Emit gate 0–1 by default; deepen optionally
- Completion criterion: `check-spec.sh` exits clean
- Handoff: `run specs/<slug>.yaml` or `yarn harness:extend`

### review-harness-spec

Triggers when you say: "review my harness spec", "is this ready to run", "audit my acceptance contract", "review my .harness extend spec".

**Provides:**

- **Wiring** axis — script output (slug, REPLACE_ME, install name, gate pairing, blind scan, extend.baseline)
- **Oracle** axis — journey↔assertion traceability, severity budget, thin Playwright, needles, extend-specific checks
- Side-by-side report (axes stay separate)

## Glossary (leading words)

| Term | Meaning |
|------|---------|
| **spec** | The coupled set of files for one benchmark |
| **spec file** | `specs/<name>.yaml` or `.harness/spec.yaml` |
| **slug** | Kebab name for the spec file `name` field |
| **run** | Greenfield CLI mode (seed + isolated workspace) |
| **extend** | In-place CLI mode (`.harness/`, no seed) |
| **blind** | Keep oracle text out of the PRD |
| **oracle** | Acceptance contract JSON |
| **gate** | Validation tier that can stop a run |
| **needle** | Static text assertion |

Full definitions: `skills/harness-spec-anatomy/GLOSSARY.md`.

## Works With

- Claude Code
- Codex CLI
- Gemini CLI
- Cursor and any agent that supports the skills/plugin format
- [hedera-harness](https://github.com/hedera-dev/hedera-harness) CLI (`run`, `extend`, `validate`, `validate-semantic`)
- Optional: [mattpocock/skills](https://github.com/mattpocock/skills) `/grilling` (preferred when present)

## License

Apache-2.0
