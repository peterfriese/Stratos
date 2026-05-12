# Stratos Implementation Journal

A chronological record of building the Stratos skills - decisions, discoveries, and lessons learned.

---

## Implementation Journey

### Day 1: Initial Setup (2025-05-12)

**What we did:**
1. Created GitHub repository `peterfriese/Stratos` (private)
2. Initialized git repo with a simple README
3. Created directory structure for three skills

**What we learned:**
- The `npx skills add` command installs from GitHub repo root
- Option A (sub-skills in single repo) is the best approach - allows independent discovery while keeping brand cohesive
- Luca.tools supports `--skill` flag for installing specific subdirectories

---

### Day 1: Skill Creation

**What we did:**
1. Created `stratos-core/SKILL.md` (279 lines)
   - Progressive Disclosure principle
   - Four-layer methodology (Troposphere → Thermosphere)
   - Laws of Physics (Call Site First, Avoid Init-Bloat, Semantic Naming)
   - Rejection criteria (Boolean Traps, Stringly-Typed APIs)

2. Created `stratos-swiftui/SKILL.md` (280 lines)
   - Role: Component Designer
   - Activation triggers
   - Core principles with call site examples
   - Component design patterns (Container, Modifier Chain, EnvironmentKey, Style Protocols)
   - Rejection criteria

3. Created `stratos-swift/SKILL.md` (328 lines)
   - Role: SDK Engineer
   - Activation triggers
   - Swift 6 concurrency patterns (Actors, Sendable, AsyncSequence)
   - Result-builder APIs
   - Library evolution guidelines

4. Created reference documents:
   - `stratos-swiftui/references/LAYERS.md`
   - `stratos-swift/references/LAYERS.md`

**What we learned:**
- agentskills.io spec itself follows progressive disclosure - this aligned perfectly with Stratos philosophy
- SKILL.md files should stay under 500 lines (we're at ~280-330)
- References should be one level deep (references/LAYERS.md, not deeper)
- Each skill needs clear "Activation Triggers" to help agents decide when to activate

---

### Day 1: Validation Script

**What we did:**
Created `scripts/validate-skills.swift` to validate:
- YAML frontmatter format
- Name format (lowercase, hyphens, no leading/trailing hyphens)
- Description length (1-1024 chars)
- References structure (flat, one level deep)

**What we learned:**
- Swift scripts need specific syntax - had to fix `firstIndex(of:after:)` issue (doesn't exist in Swift)
- The YAML parser initially only captured single-line values - multiline descriptions with `|` were being truncated to 1 character
- The spec's 64-char name limit and 1024-char description limit are strict requirements

---

### Day 1: Bug Fix - Multiline YAML Parsing (2025-05-12)

**Problem:** Validation script reported descriptions as "1 char" even though they were 200+ characters.

**Root cause:** The regex `(\w+):\s*(.*)` only captured the first line after the colon. Multiline YAML uses `|` or `>` indicators which continue on subsequent indented lines.

**Fix applied:**
- Rewrote `parseFrontmatter()` to detect multiline indicators (`|` or `>`)
- Collect all indented lines that belong to the multiline value
- Stop at the next non-indented top-level key

**Verification:**
```
✓ [stratos-swiftui] description is valid (243 chars)
✓ [stratos-swift] description is valid (265 chars)
✓ [stratos-core] description is valid (291 chars)
```

**What we learned:**
- Always test YAML parsing with actual multiline content
- The agentskills.io spec uses `|` for multiline descriptions - this is a common pattern
- Validation scripts should verify content, not just structure

---

### Day 1: Documentation Structure

**What we did:**
1. Renamed `docs/README.md` → `docs/JOURNAL.md`
2. Created `docs/DEVELOPMENT.md` with guidelines for future work

**What we learned:**
- Clear separation between "what happened" (JOURNAL) vs "how to do things" (DEVELOPMENT) follows the same principles we teach
- Always document learnings immediately - don't rely on memory

---

### Day 2: Deduplication (2025-05-12)

**Problem:** Significant duplication across skills:
1. "When to Apply" (stratos-core) vs "Activation Triggers" - nearly identical
2. Progressive Disclosure + Four Layers - full in core, abbreviated tables in swiftui/swift
3. Call Site First - repeated in all three skills
4. Boolean Traps - repeated in core and swiftui
5. Stringly-Typed APIs - repeated in core and swift

**Fix applied:**
1. Removed "When to Apply" section from stratos-core (redundant with Activation Triggers)
2. Replaced abbreviated PD + layers tables in swiftui/swift with references to stratos-core
3. Replaced duplicate rejection criteria in swiftui/swift with references to stratos-core

**Verification:**
```
stratos-core:   279 → 271 lines (-8)
stratos-swiftui: 280 → 216 lines (-64)
stratos-swift:   328 → 286 lines (-42)
Total removed: ~114 lines
```

**What we learned:**
- Orthogonal skills should reference, not repeat
- "When to Apply" and "Activation Triggers" serve different purposes conceptually, but the content was redundant - resolved by keeping only triggers
- Each skill should keep only what makes it unique (swiftui: patterns, swift: concurrency/builders, core: methodology)
- References in SKILL.md work well for linking to other skills

---

## Decisions Made

### 1. Repo Structure

**Decision**: Use sub-skills in a single repo (Option A).

**Rationale**:
- Keeps brand cohesive under "Stratos"
- Each skill is independently discoverable
- Works with `npx skills add peterfriese/Stratos@stratos-*`
- Luca.tools supports `--skill` flag for sub-directory installation

### 2. Orthogonal Skills

**Decision**: Keep skills orthogonal - stratos-swiftui and stratos-swift reference (not include) stratos-core.

**Rationale**:
- Simpler activation logic
- Easier to test independently
- Can run evals later to compare with embedding core principles directly

### 3. Documentation Location

**Decision**: Use `docs/JOURNAL.md` for implementation log, `docs/DEVELOPMENT.md` for development guidance, `references/` for skill-specific technical details.

**Rationale**:
- `docs/JOURNAL.md` - what happened, decisions made, lessons learned
- `docs/DEVELOPMENT.md` - how to develop future skills
- `references/` - detailed technical content agents can load on demand
- Clear separation of concerns

### 4. Naming Convention

**Decision**: Use `stratos-core`, `stratos-swiftui`, `stratos-swift` (no prefix/suffix).

**Rationale**:
- Simple, clean names
- Follow agentskills.io spec (lowercase, hyphens allowed)
- Aligned with Swift naming conventions

---

## Current Structure

```
Stratos/
├── AGENTS.md                 # All-in-one development guidance
├── stratos-core/
│   └── SKILL.md              # Core methodology (271 lines)
├── stratos-swiftui/
│   ├── SKILL.md              # SwiftUI skill (216 lines)
│   └── references/
│       └── LAYERS.md         # Detailed layer guidance
├── stratos-swift/
│   ├── SKILL.md              # Swift skill (286 lines)
│   └── references/
│       └── LAYERS.md         # Detailed layer guidance
├── docs/
│   └── JOURNAL.md           # Implementation journey
└── scripts/
    └── validate-skills.swift # Validation script
```

---

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

---

## Future Work

- [ ] Run evals comparing orthogonal vs embedded stratos-core
- [ ] Add example code to references
- [ ] Create Swift package for common utilities
- [ ] Consider adding TypeScript/React skill following same pattern
- [ ] Publish to SkillRegistry for broader discovery

---

## Notes

- Each SKILL.md includes "See Also" sections linking to related skills
- References are designed to be loaded on-demand (progressive disclosure)
- Validation script uses Swift as per user preference for Swift community alignment
- Always document learnings in JOURNAL.md when making changes