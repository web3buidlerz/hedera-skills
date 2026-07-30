# Hedera Harness

Agent skills for **authoring and reviewing** [hedera-harness](https://github.com/hedera-dev/hedera-harness) benchmark packs — PRD, spec YAML, validators, Playwright smoke, and acceptance contracts that drive Scaffold HBAR template generation.

These skills are for the human or agent writing the pack **before** a run. They are **not** generator skills: do not list them in a template spec's `skills:` field (that list is vendored into the run workspace for the coding agent that builds the demo).

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
| `harness-spec-author` | Interactive workflow: intake a product idea → emit a Tier 0–1 pack → optionally deepen to Tier 2 / 3 / 3.5 |
| `harness-spec-review` | Audit an existing pack for cross-file inconsistencies, tier misconfiguration, and oracle-integrity issues before burning a run |

### harness-spec-author

Triggers when you say: "create a harness spec", "author a hedera-harness PRD", "build a scaffold-hbar benchmark", "write an acceptance contract", "set up Tier 0–3 validators", "turn this demo idea into harness inputs".

**Provides:**

- Locate-harness / reconstruct-from-references workflow
- Batched intake (product, Hedera services, routes, wallet vs read path, tier ambition)
- Skeleton copy + slug rename aligned with the harness Quickstart
- Compact Tier 0–1 templates and a name-consistency map
- Journey → `C1…Cn` acceptance-contract guidance
- Tier enable order and host prerequisites
- Generator `skills:` recommendations from `skills-index.json` (never this plugin)

### harness-spec-review

Triggers when you say: "review my harness spec", "check this benchmark pack", "audit my acceptance contract", "is this pack ready to run".

**Provides:**

- Cross-file identity / path checks
- Tier prerequisite validation (`contract` + `validator.enabled`, `chainValidation.network: testnet`, …)
- Severity budget and thin-Playwright checks
- Oracle-integrity check (no contract text in the PRD)
- Blocker / warning / OK report with next CLI commands

## Key design rules

1. **Two audiences** — authoring skills (this plugin) vs generator skills (`hedera-consensus-service`, `hts-system-contract`, …). Never conflate them.
2. **Oracle integrity** — PRD is product-facing; the acceptance contract is the grading oracle. Do not paste `C1` / `howToVerify` into the PRD.
3. **Tier 0–1 first** — keep Playwright, contract, validator, and `chainValidation` commented until lower tiers are green.
4. **Hybrid templates** — Tier 0–1 bodies live in `references/`; Tier 2 / 3 / 3.5 bodies come from harness `skeletons/new-template/` (local clone or pinned GitHub raw).

## Works With

- Claude Code
- Codex CLI
- Gemini CLI
- Cursor and any agent that supports the skills/plugin format
- [hedera-harness](https://github.com/hedera-dev/hedera-harness) CLI (`run`, `validate`, `validate-semantic`)

## License

Apache-2.0
