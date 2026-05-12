# Stratos Development Guide

Guidelines for developing and maintaining Stratos skills.

---

## Overview

This guide explains how to create new skills, update existing ones, and maintain documentation. Following these guidelines ensures consistency across the Stratos suite.

---

## Before You Start

### Read the Specification

Always reference the official [Agent Skills specification](https://agentskills.io/specification) for:
- YAML frontmatter requirements (name, description limits)
- Directory structure rules
- Progressive disclosure recommendations

### Understand Stratos Philosophy

Read [stratos-core/SKILL.md](../stratos-core/SKILL.md) to understand:
- Progressive Disclosure principle
- Four-layer methodology (Troposphere → Thermosphere)
- Laws of Physics (Call Site First, Avoid Init-Bloat, Semantic Naming)

---

## Creating a New Skill

### 1. Choose a Name

Follow agentskills.io naming rules:
- Max 64 characters
- Lowercase letters, numbers, hyphens only
- Cannot start or end with hyphen
- No consecutive hyphens

```
Valid: stratos-swiftui, api-validator
Invalid: SwiftUI, stratos--core, -core
```

### 2. Create Directory Structure

```
stratos-new-skill/
├── SKILL.md              # Required
├── references/           # Optional
│   └── LAYERS.md         # Detailed guidance
├── scripts/              # Optional
└── assets/               # Optional
```

### 3. Write SKILL.md

**Frontmatter (required):**
```yaml
---
name: stratos-new-skill
description: |
  A clear description of what this skill does and when to use it.
  Use when [specific trigger scenario].
metadata:
  author: peterfriese
  version: "1.0"
---
```

**Body structure:**
1. **Role** - What the skill is/does
2. **Activation Triggers** - When to activate this skill
3. **Core Principles** - Key guidelines
4. **Common Tasks** - Typical workflows
5. **Rejection Criteria** - What to avoid
6. **See Also** - Links to related skills

**Line count target:** Keep SKILL.md under 500 lines. Move detailed content to `references/`.

### 4. Add References (Optional)

If SKILL.md exceeds ~300 lines, create `references/LAYERS.md` with:
- Detailed implementation patterns
- Code examples
- Decision trees
- Anti-patterns

Reference files should be:
- One level deep from SKILL.md (references/LAYERS.md, not deeper)
- Focused on a single topic
- Loaded on-demand by agents

---

## Updating Existing Skills

### Making Changes

1. **Small changes** - Edit directly in SKILL.md
2. **Large changes** - Consider moving content to references/
3. **Breaking changes** - Update version in metadata

### Always Document Learnings

**IMPORTANT:** When you make changes, document what you learned in `docs/JOURNAL.md`.

Include:
- What changed
- Why it changed
- What you learned
- Date of change

Example entry:
```markdown
### 2025-05-12: Fixed YAML Parsing Bug

**Problem:** Validation script truncated multiline descriptions to 1 char.

**Fix:** Rewrote parseFrontmatter() to handle `|` and `>` indicators.

**What we learned:** Always test YAML parsing with actual multiline content.
```

---

## Validation

### Run the Validation Script

Before committing, run:
```bash
swift scripts/validate-skills.swift
```

This validates:
- YAML frontmatter format
- Name format (lowercase, hyphens)
- Description length (1-1024 chars)
- References structure (flat)

### Manual Checks

1. **Read the skill from an agent's perspective** - Would you know when to activate it?
2. **Check call sites** - Are they realistic and ergonomic?
3. **Verify references** - Are linked files accurate?
4. **Test progressive disclosure** - Does SKILL.md stay simple, with details in references?

---

## Testing Skills

### Local Testing

Install skills locally using:
```bash
# npx skills
npx skills add peterfriese/Stratos@stratos-core --path ./stratos-core

# luca.tools
luca install peterfriese/Stratos --skill stratos-core
```

### Evaluation

Consider running evals to compare:
- Orthogonal vs embedded core principles
- Different description wording
- Activation trigger effectiveness

---

## Publishing

### Private to Public

When ready to make public:
1. Update repo visibility on GitHub
2. Test all installation methods
3. Update README.md with public installation commands
4. Consider submitting to SkillRegistry

### Versioning

Follow semantic versioning for skill metadata:
- **Major**: Breaking changes to API/behavior
- **Minor**: New features, backward compatible
- **Patch**: Bug fixes, documentation updates

---

## Quick Reference

| Task | File | Notes |
|------|------|-------|
| Create new skill | `stratos-*/SKILL.md` | Follow naming rules |
| Add detailed guidance | `references/LAYERS.md` | One level deep |
| Document changes | `docs/JOURNAL.md` | Always include date |
| Development guidelines | `docs/DEVELOPMENT.md` | This file |
| Validate before commit | `swift scripts/validate-skills.swift` | Run locally |

---

## See Also

- [Agent Skills Specification](https://agentskills.io/specification)
- [stratos-core/SKILL.md](../stratos-core/SKILL.md)
- [docs/JOURNAL.md](./JOURNAL.md)