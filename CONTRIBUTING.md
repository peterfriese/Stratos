# Contributing to Stratos

Thank you for your interest in contributing to Stratos! This document provides guidelines and instructions for contributing.

---

## Adding New Skills

### Directory Structure

```
stratos-new-skill/
├── SKILL.md              # Required: skill definition (~250-350 lines)
├── references/           # Optional: detailed guidance
│   └── LAYERS.md         # One level deep only
└── scripts/              # Optional: executable scripts
```

### SKILL.md Requirements

1. **Frontmatter** (required):
   ```yaml
   ---
   name: skill-name
   description: |
     Clear description of what this skill does and when to use it.
     Use when [specific trigger scenario].
   metadata:
     author: peterfriese
     version: "1.2"
   ---
   ```

2. **Naming Rules**:
   - Max 64 characters
   - Lowercase letters, numbers, hyphens only
   - No leading/trailing hyphens, no consecutive hyphens
   - Must match parent directory name

3. **Sections** (required in order):
   - Role
   - Activation Triggers
   - Core Principles
   - Common Tasks
   - Rejection Criteria
   - See Also

### Reference Files

- Store detailed content in `references/*.md`
- One level deep only (no nested directories)
- Load on-demand for progressive disclosure

---

## Validation

Before committing, run the validation script:

```bash
swift scripts/validate-skills.swift
```

This validates:
- YAML frontmatter format (`name`, `description`, `metadata.author`, `metadata.version`)
- Name format (lowercase, hyphens, max 64 chars, matches parent directory)
- Description length (1-1024 chars)
- Required section presence and ordering (`Role` → `Activation Triggers` → `Core Principles` → `Common Tasks` → `Rejection Criteria` → `See Also`)
- Line count budget (warns at >350 lines, errors at >500 lines)
- Relative Markdown links in `SKILL.md` and `references/*.md`
- References structure (flat, one level deep)

---

## Documentation

When making changes, document your learnings in `docs/JOURNAL.md` (in reverse chronological order at the top of the Implementation Journey section):

```markdown
### Entry N: [Brief Title] (YYYY-MM-DD)

**Problem:** What issue did you solve or what did you add?

**Fix:** What changes did you make?

**What we learned:** Key takeaways for future development.
```

---

## Code Style

- Keep `SKILL.md` files within ~250-350 lines (max 500 lines)
- Use `---` for section separators (standard Markdown)
- Reference other skills using relative paths: `[stratos-core](../stratos-core/SKILL.md)`
- Include "Further Reading" section with relevant links

---

## Questions?

Open an issue on GitHub for questions about contributing.