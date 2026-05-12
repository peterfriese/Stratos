# Stratos Implementation Log

## Overview

Stratos is a suite of AI agent skills for High-End API Design following the principle of Progressive Disclosure.

## Decisions Made

### 1. Repo Structure (2025-05-12)

**Decision**: Use sub-skills in a single repo (Option A).

**Rationale**:
- Keeps brand cohesive under "Stratos"
- Each skill is independently discoverable
- Works with `npx skills add peterfriese/Stratos@stratos-*`
- Luca.tools supports `--skill` flag for sub-directory installation

### 2. Orthogonal Skills (2025-05-12)

**Decision**: Keep skills orthogonal - stratos-swiftui and stratos-swift reference (not include) stratos-core.

**Rationale**:
- Simpler activation logic
- Easier to test independently
- Can run evals later to compare with embedding core principles directly

### 3. Documentation Location (2025-05-12)

**Decision**: Use `docs/` for implementation log, `references/` for skill-specific details.

**Rationale**:
- `docs/` - internal notes about the project (what we decided, why)
- `references/` - detailed technical content agents can load on demand
- Clear separation between "how we built this" vs "how to use this"

### 4. Naming Convention (2025-05-12)

**Decision**: Use `stratos-core`, `stratos-swiftui`, `stratos-swift` (no prefix/suffix).

**Rationale**:
- Simple, clean names
- Follow agentskills.io spec (lowercase, hyphens allowed)
- Aligned with Swift naming conventions

## Structure Created

```
Stratos/
├── stratos-core/
│   └── SKILL.md              # Core methodology (~250 lines)
├── stratos-swiftui/
│   ├── SKILL.md              # SwiftUI skill (~280 lines)
│   └── references/
│       └── LAYERS.md         # Detailed layer guidance
├── stratos-swift/
│   ├── SKILL.md              # Swift skill (~280 lines)
│   └── references/
│       └── LAYERS.md         # Detailed layer guidance
├── docs/
│   └── README.md            # This file
└── scripts/
    └── validate-skills.swift # Validation script (pending)
```

## What We Learned

### 1. Progressive Disclosure in Skills

The agentskills.io spec itself follows progressive disclosure:
- Metadata (~100 tokens) loaded at startup
- SKILL.md body (<5000 tokens recommended) loaded on activation
- References loaded only when needed

This aligned perfectly with Stratos' philosophy.

### 2. Reference File Strategy

- Keeping SKILL.md files under 500 lines (actual: ~250-280 lines each)
- Moving detailed guidance to `references/LAYERS.md`
- One level deep from SKILL.md (references/LAYERS.md, not deeper)

### 3. Skill Activation Triggers

Each skill now has clear "Activation Triggers" section to help agents decide when to activate.

## Installation Commands

```bash
# Using npx (Vercel skills CLI)
npx skills add peterfriese/Stratos@stratos-core
npx skills add peterfriese/Stratos@stratos-swiftui
npx skills add peterfriese/Stratos@stratos-swift

# Using luca.tools
luca install peterfriese/Stratos --skill stratos-core
luca install peterfriese/Stratos --skill stratos-swiftui
luca install peterfriese/Stratos --skill stratos-swift
```

## Future Work

- [ ] Run evals comparing orthogonal vs embedded stratos-core
- [ ] Add example code to references
- [ ] Create Swift package for common utilities
- [ ] Consider adding TypeScript/React skill following same pattern
- [ ] Publish to SkillRegistry for broader discovery

## Notes

- Each SKILL.md includes "See Also" sections linking to related skills
- References are designed to be loaded on-demand (progressive disclosure)
- Validation script uses Swift as per user preference for Swift community alignment