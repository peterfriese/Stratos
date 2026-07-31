# Guidance for AI Agents Working on Stratos

## Quick Start: When to Activate Which Skill

- **stratos-core**: When designing APIs, reviewing code quality, or discussing Progressive Disclosure principles
- **stratos-swiftui**: When building reusable SwiftUI components, ViewModifiers, or custom Styles
- **stratos-swift**: When creating Swift libraries, SDKs, or implementing Swift 6 concurrency patterns

## Skill Structure

```
stratos-*/
├── SKILL.md              # Required: skill definition (~250-350 lines)
├── references/           # Optional: detailed technical guidance
│   └── LAYERS.md         # One level deep only
└── scripts/              # Optional: executable scripts
```

### Naming Rules

- Max 64 characters
- Lowercase letters, numbers, hyphens only
- No leading/trailing hyphens, no consecutive hyphens
- Must match parent directory name

### Frontmatter Requirements

```yaml
---
name: skill-name
description: |
  Clear description of what this skill does and when to use it.
  Use when [specific trigger scenario].
metadata:
  author: peterfriese
  version: "1.0"
---
```

## Creating a New Skill

1. Create directory: `stratos-new-skill/`
2. Add `SKILL.md` with proper frontmatter
3. Add content: Role, Activation Triggers, Core Principles, Common Tasks, Rejection Criteria, See Also
4. If SKILL.md exceeds ~300 lines, move details to `references/LAYERS.md`

## Updating Existing Skills

1. Make changes directly in SKILL.md for small updates
2. Move content to references/ for large changes
3. Update version in metadata for breaking changes

## Validation

**Always run validation before committing:**

```bash
swift scripts/validate-skills.swift
```

This validates:
- YAML frontmatter format
- Name format (lowercase, hyphens)
- Description length (1-1024 chars)
- References structure (flat, one level deep)

## Documentation Rule

**IMPORTANT:** When making changes, always document learnings in `docs/JOURNAL.md`.

Include:
- What changed
- Why it changed
- What you learned
- Date of change

Example:
```markdown
### 2025-05-12: Fixed Multiline YAML Parsing

**Problem:** Validation script truncated multiline descriptions.

**Fix:** Rewrote parseFrontmatter() to handle | and > indicators.

**What we learned:** Always test YAML parsing with actual multiline content.
```

## Progressive Disclosure in Skill Development

Follow the same principle we teach:

- **SKILL.md**: Keep simple, ~250-350 lines, covers essentials
- **references/**: Load on-demand for detailed guidance
- Don't over-engineer - prefer practical over perfect

---

## OpenCode Agent Fleet

Stratos uses a **Chief of Staff** orchestration model — a single primary agent orchestrates a fleet of specialized subagents. The default `build` and `plan` agents are disabled; all work flows through the CoS. Configuration lives in `opencode.jsonc` and `.opencode/agents/`.

### Provider Strategy

Two providers are configured in `opencode.jsonc`:

| Provider | Model Prefix | Cost Model | Use Case |
|----------|-------------|------------|----------|
| **Go** | `opencode-go/` | $10/mo subscription | Primary — all agents route here for cost efficiency |
| **Zen** | `opencode/` | Pay-as-you-go | Fallback — models unavailable on Go |

### Chief of Staff (Sole Primary Agent)

| Agent | Model | Role |
|-------|-------|------|
| **chief-of-staff** | Go / DeepSeek V4 Flash | Orchestrator — analyzes requirements, creates plans, delegates to subagents, synthesizes results. Read-only: no edit, no bash. $10/mo flat (Go sub). |

### Subagents (@-mentionable)

| Agent | Model | Cost | Purpose |
|-------|-------|------|---------|
| **skill-architect** | Go / DeepSeek V4 Flash | $10/mo (Go sub) | Scaffold new skills, validate structure, naming, frontmatter |
| **content-writer** | Go / DeepSeek V4 Flash | $10/mo (Go sub) | Write/edit SKILL.md content following Stratos methodology |
| **validator** | Go / DeepSeek V4 Flash | $10/mo (Go sub) | Run `validate-skills.swift`, fix compliance issues |
| **reviewer** | Go / DeepSeek V4 Pro | $1.74/$3.48 per 1M | Deep quality review of skill accuracy and consistency |
| **journalist** | Go / DeepSeek V4 Flash | $10/mo (Go sub) | Maintain `docs/JOURNAL.md` with change records |

### Cost-Saving Rules

1. **CoS runs on Flash**: DeepSeek V4 Flash via Go supports ~158K requests/month within the $10 flat fee. The CoS is read-only orchestration — Flash is more than sufficient.
2. **Most subagents on Flash**: skill-architect, content-writer, validator, and journalist all use Flash for maximum request budget.
3. **reviewer on Pro**: DeepSeek V4 Pro for nuanced quality review. Invoke sparingly — only for substantive cross-skill audits.

---

## Session & Process Rules

### 1. Phase Gate Checkpoint

Before executing ANY implementation task, you MUST:
- Present a 2-3 bullet plan of what you're about to do
- Wait for user confirmation before proceeding

### 2. Validation Discipline

- NEVER claim validation passes without actually running `swift scripts/validate-skills.swift`
- If the same validation issue persists after 2 fix attempts, STOP and ask the user for strategy
- Run validation BEFORE and AFTER any skill changes

### 3. Documentation Sync (Every Task)

After completing any task, update relevant docs:
- `docs/JOURNAL.md` — add entry for non-trivial changes
- `AGENTS.md` — add any new rules, patterns, or lessons learned

### 4. Prohibited Patterns

- Never add boilerplate to SKILL.md (introductions, filler, motivational text)
- Never create files outside the established `stratos-*/` structure
- Never write to `AGENTS.md` directly from a subagent — route through the Chief of Staff
- Never commit `xcode-skills/` — personal reference material, kept local-only via `.gitignore`

### 5. When to Delegate to Subagents

| If the task is... | Then... |
|---|---|---|
| Creating a new skill | `@skill-architect` → `@content-writer` → `@validator` |
| Editing SKILL.md content | `@content-writer` → `@validator` |
| Fixing validation failures | `@validator` |
| Cross-skill quality audit | `@reviewer` |
| Updating JOURNAL.md | `@journalist` |

### 6. Git & Conventional Commits

All commits MUST follow [Conventional Commits](https://www.conventionalcommits.org/):
- `feat:` — new skill
- `fix:` — skill content correction
- `chore:` — tooling, config, CI, project setup
- `docs:` — documentation only (JOURNAL.md, README)
- `refactor:` — code/script change that is neither a fix nor a feature

Keep commit messages concise (<72 chars for the subject line).

### 7. Self-Improvement

Keep this file current. After every significant change (new dependency, new pattern, new workflow rule), update `AGENTS.md` to reflect it. This file is your primary memory across sessions — if it's stale, you'll repeat the same mistakes.

---

## See Also

- [stratos-core/SKILL.md](stratos-core/SKILL.md) — Core methodology
- [docs/JOURNAL.md](docs/JOURNAL.md) — Implementation journey
- [Agent Skills Specification](https://agentskills.io/specification)
