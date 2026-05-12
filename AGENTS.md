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
├── scripts/              # Optional: executable scripts
└── assets/               # Optional: templates, resources
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

## See Also

- [stratos-core/SKILL.md](stratos-core/SKILL.md) - Core methodology
- [docs/JOURNAL.md](docs/JOURNAL.md) - Implementation journey
- [Agent Skills Specification](https://agentskills.io/specification)