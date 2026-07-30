---
name: harness-spec-author
description: >-
  Author a hedera-harness benchmark pack from a product idea — PRD, spec.yaml,
  static and yarn validators, optional Playwright smoke and acceptance contract.
  Use when the user asks to create a harness spec, write a hedera-harness PRD,
  build a scaffold-hbar benchmark, author an acceptance contract, set up Tier
  0–3 validators, or turn a Hedera demo idea into harness inputs.
---

# Harness Spec Author

Turn a Hedera product idea into a complete **benchmark pack** for
[hedera-harness](https://github.com/hedera-dev/hedera-harness). The pack is six
coupled files; judgment matters more than the `cp` + `sed` boilerplate.

**This skill is for authoring packs — not for generator runs.** Never add
`harness-spec-author` or `harness-spec-review` to a template spec's `skills:`
list. Those skills are vendored into the run workspace so the generator builds
the demo. Recommend existing index names (`hedera-consensus-service`,
`hedera-token-service`, `hts-system-contract`, `project-scaffolding`, …) instead.

**Oracle integrity:** the PRD is product-facing (vendored to the generator); the
acceptance contract is the grading oracle. Never paste numbered contract
assertions (`C1`, `howToVerify`, severity labels) into the PRD. Doing so
destroys the blind-generation property.

## Step 1: Locate the harness

Confirm the working directory is a hedera-harness clone by checking for:

- `specs/`
- `skeletons/new-template/`
- `skills-index.json`

**If yes:** copy skeletons from disk (preferred — always current).

**If no:** ask where to write the pack. Reconstruct Tier 0–1 files from
`references/pack-anatomy.md`. For Tier 2 / 3 / 3.5 bodies, fetch the harness
skeletons at the pinned ref in `references/tier-strategy.md` (or ask the user
to clone hedera-harness).

## Step 2: Intake (batches of 2–3)

Ask interactively. Skip questions the user already answered.

**Batch 1 — Product**

1. What is the demo in one paragraph? (goal + "done" in a browser without live credentials)
2. Who is it for?
3. Suggested kebab-case slug (e.g. `proof-wall`, `x402-metered-api`)

**Batch 2 — Hedera + UI**

4. Which Hedera services? (HCS, HTS, HSS, Solidity/precompiles, mirror reads, …)
5. Routes the app will expose (at least `/`)
6. What works **without a wallet** vs what is **wallet-gated**?

**Batch 3 — Constraints + ambition**

7. Solidity / Hardhat / Foundry — yes or no? (drives `forbiddenWorkspaces` / forbidden files)
8. Target tier for the first green run? Default: **Tier 0–1 only**. Offer Tier 2 / 3 later.
9. Any generator skills to vendor? (names from harness `skills-index.json`)

## Step 3: Pick the slug and copy skeletons

```bash
NAME=<kebab-slug>

cp skeletons/new-template/prd.md              docs/prds/${NAME}.md
cp skeletons/new-template/spec.yaml           specs/${NAME}.yaml
cp skeletons/new-template/acceptance-contract.json contracts/${NAME}-acceptance.json
cp skeletons/new-template/static.json         validators/${NAME}-static.json
cp skeletons/new-template/yarn.json           validators/${NAME}-yarn.json
cp skeletons/new-template/playwright-smoke.yaml playwright/${NAME}-smoke.yaml

# Align internal paths / names with $NAME (macOS; on Linux drop the '').
sed -i '' "s/my-template/${NAME}/g" \
  specs/${NAME}.yaml \
  validators/${NAME}-static.json \
  validators/${NAME}-yarn.json \
  contracts/${NAME}-acceptance.json \
  playwright/${NAME}-smoke.yaml
```

Without a harness clone, create the same paths under the user-chosen root using
the compact Tier 0–1 bodies in `references/pack-anatomy.md`, then rename
`my-template` → `$NAME`.

## Step 4: Emit Tier 0–1

Fill remaining `REPLACE_ME` stubs. Keep Tier 2 / 3 / 3.5 **commented** in the
spec unless the user explicitly wants them now.

| File | Guidance |
|------|----------|
| `docs/prds/${NAME}.md` | Follow `references/prd-and-journeys.md` |
| `specs/${NAME}.yaml` | Fill `description`; set `skills:` from Batch 3; leave `contract` / `validator` / `validators.playwright` / `chainValidation` commented |
| `validators/${NAME}-static.json` | Align `template.json` name / capabilities; README/AGENTS needles to real yarn scripts |
| `validators/${NAME}-yarn.json` | Keep a command literally named `install`; lint + production build; no live secrets |

Read `references/pack-anatomy.md` for embedded bodies and the name-consistency map.

### Recommend `skills:` names

Map Hedera services → names registered in the harness `skills-index.json`
(preferred) or the public hedera-skills repo:

| Service / need | Typical skill name |
|----------------|--------------------|
| HCS topics / messages | `hedera-consensus-service` |
| HTS via JS SDK | `hedera-token-service` |
| HTS Solidity precompile | `hts-system-contract` |
| Scaffold / CLAUDE.md patterns | `project-scaffolding` |

Do **not** recommend this plugin's author/review skills for `skills:`.

## Step 5: Optionally deepen (Tier 2 / 3 / 3.5)

Only after Tier 0–1 files are coherent. See `references/tier-strategy.md`.

1. **Tier 2** — fill `playwright/${NAME}-smoke.yaml` routes; uncomment
   `validators.playwright` in the spec. Keep it thin (boot + HTTP + crash text).
2. **Tier 3** — fill `contracts/${NAME}-acceptance.json` from PRD journeys
   (`references/acceptance-contract-guide.md`); uncomment `contract` +
   `validator` in the spec.
3. **Tier 3.5** — advanced only; needs funded ECDSA testnet operator env vars
   and `executableWithTestSigner` assertions. Keep commented by default.

## Step 6: Self-check and hand off

Run this checklist before claiming the pack is ready:

- [ ] Slug consistent across `spec.name`, `templateMetadata.name`, static
      `template.json` name, and (if present) contract `template`
- [ ] `spec.prd` path exists; contract `prd` (if present) matches
- [ ] Routes in Playwright / contract agree with the PRD journeys
- [ ] No contract assertion text mirrored into the PRD
- [ ] Command validator has `name: install`
- [ ] Higher tiers still commented unless the user asked for them

Then suggest:

```bash
# Prefer reviewing the pack first (harness-spec-review skill), then:
npm run harness -- validate specs/${NAME}.yaml --workspace runs/<id>/workspace
# After a seeded workspace exists — or go straight to:
npm run harness -- run specs/${NAME}.yaml --max-attempts 3
```

Point the user at the harness README for install, `agent` auth, and Tier 2/3
host prerequisites. Do not expand CLI teaching beyond these next commands.

## Additional resources

- [prd-and-journeys.md](references/prd-and-journeys.md)
- [pack-anatomy.md](references/pack-anatomy.md)
- [acceptance-contract-guide.md](references/acceptance-contract-guide.md)
- [tier-strategy.md](references/tier-strategy.md)
