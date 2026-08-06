# Spec files

Compact Tier 0–1 bodies for reconstructing a **spec** without a harness clone.
Prefer copying `skeletons/new-template/` when available (clone / `run`). After
writing, replace every `my-template` with the **slug**. For **extend**, emit
under `.harness/` (see below). Terms: [GLOSSARY.md](../GLOSSARY.md).

## File table — clone / `run`

| File | Required? | Consumed by |
|------|-----------|-------------|
| `docs/prds/<name>.md` | Yes | Generator |
| `specs/<name>.yaml` (**spec file**) | Yes | Harness CLI (`run`) |
| `validators/<name>-static.json` | Yes | Gate 0–1 |
| `validators/<name>-yarn.json` | Yes | Gate 0–1 |
| `playwright/<name>-smoke.yaml` | Gate 2 | Playwright **gate** |
| `contracts/<name>-acceptance.json` | Gate 3 | Semantic validator (**oracle**) |

## File table — extend

Paths relative to the scaffolded project root (parent of `.harness/`).

| File | Required? | Consumed by |
|------|-----------|-------------|
| `.harness/prd.md` | Yes | Generator |
| `.harness/spec.yaml` (**spec file**) | Yes | Harness CLI (`extend`) |
| `.harness/validators/static.json` | Yes | Gate 0–1 |
| `.harness/validators/yarn.json` | Yes | Gate 0–1 |
| `.harness/playwright/<slug>-smoke.yaml` | Gate 2 | Playwright **gate** |
| `.harness/contracts/<slug>-acceptance.json` | Gate 3 | Semantic validator (**oracle**) |

## Compact Tier 0–1 bodies

### `specs/my-template.yaml`

```yaml
name: my-template
description: REPLACE_ME — one-line description of this Hedera demo benchmark.

prd: docs/prds/my-template.md
# contract: contracts/my-template-acceptance.json

seed:
  repo: https://github.com/hedera-dev/scaffold-hbar.git
  ref: main
  preflight:
    commands:
      - name: seed-install
        command: yarn install
        timeoutMs: 300000
  isolation:
    neverModifySeedRepo: true

generator:
  provider: command
  command: agent
  args:
    - -p
    - --trust
    - --sandbox
    - enabled
    - --workspace
    - "{workspace}"
    - --model
    - composer-2.5
    - --force
    - --output-format
    - stream-json
    - --stream-partial-output
  timeoutMs: 3600000

# validator:
#   enabled: true
#   provider: command
#   command: agent
#   args:
#     - -p
#     - --trust
#     - --force
#     - --sandbox
#     - disabled
#     - --approve-mcps
#     - --workspace
#     - "{workspace}"
#     - --model
#     - composer-2.5
#     - --output-format
#     - stream-json
#     - --stream-partial-output
#   timeoutMs: 600000

# skills:
#   - hedera-consensus-service
#   - project-scaffolding

constraints:
  packageManager: yarn@3.2.3
  workspaces:
    - packages/nextjs
  forbiddenCommands:
    - npm install
    - npm run
    - pnpm install
    - pnpm run

templateMetadata:
  name: my-template
  frontend: nextjs-app
  solidityFramework: none

validators:
  static: validators/my-template-static.json
  commands: validators/my-template-yarn.json
  # playwright: playwright/my-template-smoke.yaml

requiredFiles:
  - template.json
  - README.md
  - AGENTS.md
  - package.json
  - packages/nextjs/package.json

forbiddenFiles:
  - .env
  - packages/nextjs/.env

secretScan:
  failOnFiles:
    - .env
    - packages/nextjs/.env
  patterns:
    - name: private-key-assignment
      pattern: "(PRIVATE_KEY|OPERATOR_KEY|HEDERA_OPERATOR_PRIVATE_KEY)\\s*=\\s*(0x)?[0-9a-fA-F]{32,}"

maxAttempts: 3

logging:
  jsonl: runs/harness.log.jsonl
  notes: runs/harness-notes.md
```

Key loader fields: `prd`, `seed`, `generator`, `validators.static`,
`validators.commands`, `templateMetadata`, `requiredFiles`, `forbiddenFiles`,
`secretScan`, `maxAttempts`. Optional later: `contract`, `validator`,
`validators.playwright`, `chainValidation`, `skills`.

### `validators/my-template-static.json`

```json
{
  "name": "my-template-static",
  "description": "Static invariants for my-template. Adjust equals/contains to match the PRD and template.json targets.",
  "jsonAssertions": [
    {
      "file": "template.json",
      "path": "name",
      "equals": "my-template"
    },
    {
      "file": "template.json",
      "path": "create-scaffold-hbar.capabilities.frontend",
      "equals": ["nextjs-app"]
    },
    {
      "file": "package.json",
      "path": "packageManager",
      "equals": "yarn@3.2.3"
    }
  ],
  "fileAssertions": {
    "required": [
      "template.json",
      "README.md",
      "AGENTS.md",
      "package.json",
      "packages/nextjs/package.json"
    ],
    "forbidden": [".env", "packages/nextjs/.env"]
  },
  "textAssertions": [
    {
      "file": "README.md",
      "contains": ["yarn install", "yarn next:dev"]
    },
    {
      "file": "AGENTS.md",
      "contains": ["yarn next:dev"]
    }
  ]
}
```

Pin **needles** to scripts the template will actually document — not incidental
implementation detail that will churn.

### `validators/my-template-yarn.json`

```json
{
  "name": "my-template-yarn",
  "description": "Yarn commands for my-template. Keep install named \"install\" so the harness can skip it across attempts when the lockfile fingerprint is unchanged.",
  "requiresNoSecrets": true,
  "forbiddenCommands": [
    "npm install",
    "npm run",
    "pnpm install",
    "pnpm run"
  ],
  "commands": [
    {
      "name": "install",
      "command": "yarn install",
      "timeoutMs": 300000,
      "purpose": "Install workspace dependencies."
    },
    {
      "name": "lint",
      "command": "yarn lint",
      "timeoutMs": 180000,
      "purpose": "Run the template lint script."
    },
    {
      "name": "build",
      "command": "yarn next:build",
      "timeoutMs": 300000,
      "purpose": "Production build (includes TypeScript checks for Next.js templates)."
    }
  ]
}
```

The command with `"name": "install"` is load-bearing: the harness fingerprints
it across repair attempts. Renaming it silently disables the skip.

## Compact Tier 0–1 body — extend (`.harness/spec.yaml`)

No `seed`. Paths relative to the project root. `templateMetadata.name` keeps
the host template identity; `name` is the extension **slug**.

```yaml
name: my-extension
description: REPLACE_ME — in-place extension of an already-scaffolded app.

prd: .harness/prd.md
# contract: .harness/contracts/my-extension-acceptance.json

# No seed — extend runs against the already-scaffolded cwd.

generator:
  provider: command
  command: agent
  args:
    - -p
    - --trust
    - --sandbox
    - enabled
    - --workspace
    - "{workspace}"
    - --model
    - composer-2.5
    - --force
    - --output-format
    - stream-json
    - --stream-partial-output
  timeoutMs: 3600000

skills:
  - project-scaffolding
  - quality-gates

constraints:
  packageManager: yarn@3.2.3
  workspaces:
    - packages/nextjs
  forbiddenCommands:
    - npm install
    - npm run
    - pnpm install
    - pnpm run

templateMetadata:
  name: hedera-demo   # host template identity — may differ from extension slug
  frontend: nextjs-app
  solidityFramework: none

extend:
  baseline:
    commands:
      - name: install
        command: yarn install
        timeoutMs: 300000
      - name: lint
        command: yarn lint
        timeoutMs: 180000
      - name: build
        command: yarn next:build
        timeoutMs: 300000

validators:
  static: .harness/validators/static.json
  commands: .harness/validators/yarn.json
  # playwright: .harness/playwright/my-extension-smoke.yaml

requiredFiles:
  - README.md
  - AGENTS.md
  - package.json
  - packages/nextjs/package.json
  - .harness/spec.yaml
  - .harness/prd.md

forbiddenFiles:
  - .env
  - packages/nextjs/.env

secretScan:
  failOnFiles:
    - .env
    - packages/nextjs/.env
  patterns:
    - name: private-key-assignment
      pattern: "(PRIVATE_KEY|OPERATOR_KEY|HEDERA_OPERATOR_PRIVATE_KEY)\\s*=\\s*(0x)?[0-9a-fA-F]{32,}"

maxAttempts: 3

logging:
  jsonl: .harness/runs/harness.log.jsonl
  notes: .harness/runs/harness-notes.md
```

Key extend-only loader fields: `extend`, `extend.baseline`. Omit `seed`.
Static validators should assert app health / extension deliverables — not
`template.json` name (create-scaffold-hbar removes `template.json`).

Handoff: `yarn harness:extend` or `hedera-harness extend .harness/spec.yaml`.

## PRD stub

See [prd-and-journeys.md](prd-and-journeys.md). Write
`docs/prds/my-template.md` (clone / `run`) or `.harness/prd.md` (**extend**)
with Goal / Journeys / Hedera services / Non-goals / Deliverables / Acceptance
pointer. Content rules are identical; only the path differs.

## Gate 2 / 3 / 3.5 bodies

Do not embed here — they drift. Copy from the harness skeletons or follow
[tier-strategy.md](tier-strategy.md). For **extend**, place copies under
`.harness/playwright/` and `.harness/contracts/` and point the **spec file**
paths there.
