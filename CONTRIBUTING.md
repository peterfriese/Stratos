# Contributing to Stratos

Thank you for your interest in contributing to Stratos! This document provides guidelines and instructions for contributing.

---

## Adding New Skills

### Directory Structure

```
stratos-new-skill/
├── SKILL.md              # Required: skill definition
├── assets/               # Optional: icons (PNG + SVG)
│   ├── icon.png          # 512x512 recommended
│   └── icon.svg
├── references/           # Optional: detailed guidance
│   └── *.md              # One level deep only
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
     version: "1.0"
   ---
   ```

2. **Naming Rules**:
   - Max 64 characters
   - Lowercase letters, numbers, hyphens only
   - No leading/trailing hyphens
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
- YAML frontmatter format
- Name format (lowercase, hyphens, max 64 chars)
- Description length (1-1024 chars)
- References structure (flat, one level deep)

---

## Documentation

When making changes, document your learnings in `docs/JOURNAL.md`:

```markdown
### YYYY-MM-DD: [Brief Title]

**Problem:** What issue did you solve or what did you add?

**Fix:** What changes did you make?

**What we learned:** Key takeaways for future development.
```

---

## Code Style

- Keep SKILL.md files under 500 lines
- Use `---` for section separators (standard Markdown)
- Reference other skills using relative paths: `[stratos-core](../stratos-core/SKILL.md)`
- Include "Further Reading" section with relevant links

---

## Questions?

Open an issue on GitHub for questions about contributing.