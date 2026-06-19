# DevOks Team Harness

Claude Code harness for the DevOks team — plugins for code review, feature development, and Git workflows.

> **MCP & dependency setup**: [`docs/mcp-setup-guide.md`](docs/mcp-setup-guide.md)  
> **Plugin management** (create, validate, deploy): [`docs/plugin-management.md`](docs/plugin-management.md)
> **한국어 문서**: [docs/README.ko.md](docs/README.ko.md)

![DevOks Team Harness plugin map](assets/devoks-harness-engineering-final.png)

---

## Plugin Overview

| Plugin | Contents | Required |
|--------|----------|----------|
| `devoks-core` | Core principles & reference docs — SessionStart hook syncs `rules/` and `refs/` into the project `.claude/` (git-tracked; no longer gitignored) for native auto-loading | **Required** |
| `devoks-git` | Git commit, issue, and PR workflow commands | Recommended |
| `devoks-feature` | Feature development workflow (FRD/PLAN/execution skills, UI implementation) | Recommended |
| `devoks-verify` | Requirement checklist & implementation-fidelity verification + data-flow integrity verification | Recommended |
| `devoks-code` | Code review, refactoring, module analysis, and security review | Recommended |
| `devoks-test` | Automated test authoring & test-run triage | Recommended |
| `devoks-browser` | Chrome DevTools MCP attach + Visual Diff verification | Optional |

All plugins except `devoks-core` declare a dependency on `devoks-core` in the marketplace catalog.

---

## Quick Start (Minimum Dependencies)

```bash
# Required: install gh CLI
brew install gh && gh auth login

# 1. Register marketplace (once)
/plugin marketplace add ridsync/devoks-team-harness

# 2. Install plugins
/plugin install devoks-core@devoks
/plugin install devoks-git@devoks
/plugin install devoks-feature@devoks
/plugin install devoks-verify@devoks
/plugin install devoks-code@devoks
/plugin install devoks-test@devoks
```

Full dependency setup → [`docs/mcp-setup-guide.md`](docs/mcp-setup-guide.md)

---

## Plugin Installation (Claude Code Plugin System)

### Step 1: Register marketplace (once)

```bash
/plugin marketplace add ridsync/devoks-team-harness
```

### Step 2: Install plugins

```bash
/plugin install devoks-core@devoks           # required — syncs rules & refs on session start
/plugin install devoks-git@devoks            # Git workflow
/plugin install devoks-feature@devoks        # feature development
/plugin install devoks-verify@devoks         # requirement & data-flow verification
/plugin install devoks-code@devoks           # code quality & security review
/plugin install devoks-test@devoks           # test authoring & triage
/plugin install devoks-browser@devoks        # browser tools (optional)
```

### Step 3: Update

```bash
/plugin marketplace update devoks
```

---

## Fallback Installation (`setup.sh`)

Use when the plugin system is unavailable — copies commands, skills, rules, and refs directly into `.claude/`.

```bash
git clone https://github.com/ridsync/devoks-team-harness.git
cd /path/to/your-project
/path/to/devoks-team-harness/setup.sh

# update
/path/to/devoks-team-harness/setup.sh --update
```

> **Note:** `setup.sh` copies static files but does not run the `devoks-core` SessionStart hook. Re-run `setup.sh --update` after pulling harness changes to refresh rules and refs.

---

## How `devoks-core` Context Sync Works

On session start (`startup`, `resume`, `clear`, `compact`), the `devoks-core` hook runs `sync-context.sh` and:

1. Copies bundled `plugins/devoks-core/rules/*.md` → `.claude/rules/` (overwrites when the bundle changed)
2. Copies bundled `plugins/devoks-core/refs/*.md` → `.claude/refs/` (overwrites when the bundle changed)

**Policy:** The plugin bundle is the SSOT for these rules/refs, so the hook keeps each project's copy in sync with the bundle. It only copies the bundled files — project-specific files in those folders (e.g. `pitfalls.md`) are never touched. The hook does **not** modify `.gitignore`; projects track and commit `.claude/rules/` and `.claude/refs/` in git.

| Type | Files | Role |
|------|-------|------|
| **rules** | `agent-principles`, `project-convention`, `memory-policy` | Always-on agent behavior |
| **refs** | `code-review`, `engineering-principles`, `git-convention`, `workflow` | On-demand reference docs |

No slash command is needed — Claude Code loads `.claude/rules/` natively.

---

## Available Skills

| Skill | Invoke | Plugin |
|-------|--------|--------|
| `frd-author` | `/devoks-feature:frd-author` | devoks-feature |
| `plan-author` | `/devoks-feature:plan-author` | devoks-feature |
| `plan-executor` | `/devoks-feature:plan-executor` | devoks-feature |
| `feature-workflow-runner` | `/devoks-feature:feature-workflow-runner` | devoks-feature |
| `verify-requirements` | `/devoks-verify:verify-requirements` | devoks-verify |
| `verify-data-flow` | `/devoks-verify:verify-data-flow` | devoks-verify |
| `code-review` | `/devoks-code:code-review` *(agent-internal only)* | devoks-code |
| `code-security-review` | `/devoks-code:code-security-review` *(agent-internal only)* | devoks-code |
| `test-author` | `/devoks-test:test-author` | devoks-test |
| `test-run-triage` | `/devoks-test:test-run-triage` | devoks-test |
| `browser-devtools` | `/devoks-browser:browser-devtools` | devoks-browser |
| `browser-visual-diff` | `/devoks-browser:browser-visual-diff` | devoks-browser |

## Available Agents

| Agent | Plugin | Delegated by |
|-------|--------|--------------|
| `code-reviewer` | devoks-code | `code-review-general`, `code-review-diff-branch` commands |
| `code-security-reviewer` | devoks-code | `code-security-review` command |
| `browser-visual-diff-capture` | devoks-browser | `browser-visual-diff` skill (Phase 1–4) |

---

## Available Commands

### devoks-git

| Command | Description |
|---------|-------------|
| `/devoks-git:git-commit-msg` | Generate Conventional Commits message |
| `/devoks-git:git-create-issue` | Create a GitHub issue |
| `/devoks-git:git-pull-request` | Create a PR (CODEOWNERS-based reviewer assignment) |

### devoks-feature

| Command | Description |
|---------|-------------|
| `/devoks-feature:new-feature-draft` | Spec-driven feature implementation |
| `/devoks-feature:new-feature-github-issue` | GitHub issue-driven feature implementation |
| `/devoks-feature:new-ui-draft` | Figma → code UI implementation |

### devoks-code

| Command | Description |
|---------|-------------|
| `/devoks-code:code-review-general` | Scoped code review |
| `/devoks-code:code-review-diff-branch` | Branch diff code review |
| `/devoks-code:code-security-review` | Repo / dependency / threat-level security review |
| `/devoks-code:code-refactoring` | Structure, contract, and quality refactoring |
| `/devoks-code:code-analyze-module` | Module / business logic analysis |

---

## Dependency Summary

> DevOks plugins do **not** bundle general-purpose MCP servers (Figma, Playwright, Serena, CodeGraph, context7). Install them once at **user/project scope** to avoid duplicate instances and conflicts with your local MCP setup. The `devoks-core` SessionStart hook (`hooks/check-mcp.sh`) detects missing servers each session and prints install guidance. **Exception:** `devoks-browser` bundles only `chrome-devtools-attach` (`:9269` attach-specific config). See [`docs/mcp-setup-guide.md`](docs/mcp-setup-guide.md) → "설치 정책".

| Plugin | Required | Optional |
|--------|----------|----------|
| devoks-core | — | — |
| devoks-git | `gh` CLI | — |
| devoks-feature | `gh` CLI | Figma MCP, context-mode MCP |
| devoks-verify | — | context-mode MCP |
| devoks-code | CodeGraph MCP, Serena MCP | context-mode MCP |
| devoks-test | — | context-mode MCP |
| devoks-browser | Chrome DevTools MCP + `~/.claude.json` | Playwright MCP, Figma MCP |

Full setup guide → [`docs/mcp-setup-guide.md`](docs/mcp-setup-guide.md)

---

## Directory Structure

```
devoks-team-harness/
├── .claude-plugin/marketplace.json    # marketplace catalog
├── plugins/
│   ├── devoks-core/
│   │   ├── hooks/                     # SessionStart → sync-context.sh
│   │   ├── rules/                     # SSOT: agent-principles, project-convention, memory-policy
│   │   └── refs/                      # SSOT: code-review, engineering-principles, git-convention, workflow
│   ├── devoks-git/commands/           # Git commands (3)
│   ├── devoks-feature/                # feature dev (3 commands + 4 skills)
│   ├── devoks-verify/                 # verification (2 skills)
│   ├── devoks-code/                   # code quality (5 commands + 2 skills + 2 agents)
│   ├── devoks-test/                   # testing (2 skills)
│   └── devoks-browser/               # browser tools (2 skills + 1 agent)
├── shared/
│   ├── setup/claude.json.template     # ~/.claude.json MCP config template
│   └── templates/CLAUDE.md.project.template
├── docs/
│   ├── README.ko.md                   # Korean README
│   ├── mcp-setup-guide.md             # MCP dependency setup
│   ├── plugin-management.md           # plugin create · validate · deploy workflow
│   └── roadmap.md                     # future improvements (TODO)
├── setup.sh                           # fallback install script
└── README.md
```

> `plugins/devoks-core/rules/` and `plugins/devoks-core/refs/` are the SSOT for team principles and reference docs. Edit those files and commit — the SessionStart hook (or `setup.sh`) syncs them into each project's `.claude/`. Projects keep these copies git-tracked (the hook does not gitignore them).

---

## Roadmap

Planned plugin structure & content improvements are tracked in [`docs/roadmap.md`](docs/roadmap.md) (TODO format). Highlights: migrate `browser-visual-diff` → `devoks-verify:verify-visual-diff`, add a `devoks-release` plugin for the Deploy/Release phase, auto-generate the catalog tables to prevent README drift, and consolidate the severity rubric to a single SSOT.

---

## Contributing

1. Fork this repository.
2. Edit `plugins/devoks-core/rules/`, `plugins/devoks-core/refs/`, or plugin files.
3. Open a PR.
4. After merge, teammates run `/plugin marketplace update devoks` to refresh.
