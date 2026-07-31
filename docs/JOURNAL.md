# Stratos Implementation Journal

A chronological record of building the Stratos skills - decisions, discoveries, and lessons learned.

---

## Implementation Journey

### Entry 13: Distribution on skills.sh (2026-07-31)

**What changed:**
- Verified Stratos is already listed on skills.sh (skills.sh/peterfriese/stratos) — no manual submission exists; listing happens automatically via anonymous telemetry when users run `npx skills add peterfriese/Stratos`. Repo page shows 3 skills, 18 installs.
- Added the official skills.sh badge to README.md header: `[![skills.sh](https://skills.sh/b/peterfriese/Stratos)](https://skills.sh/peterfriese/Stratos)` (commit bf28a51, "docs: add skills.sh badge to README").
- Added a rule to AGENTS.md "Prohibited Patterns": never commit `xcode-skills/` (personal reference material, kept local-only via .gitignore).
- Confirmed via `git ls-files` that xcode-skills/ was never tracked (gitignored from the start) — no untrack action needed; `.gitignore` already had the entry.
- Verified CLI discovery with `npx skills add peterfriese/Stratos --list` — finds exactly 3 skills (stratos-core, stratos-swift, stratos-swiftui).
- Ran `swift scripts/validate-skills.swift` — all validations passed.
- Changes are committed locally on main but NOT yet pushed.

**Why it changed:**
- Newsletter mention drove GitHub stars 0→12; wanted more distribution. skills.sh ranks by install count, so visibility = people running the install command; the badge adds cross-linking and install-count proof on the README.

**What we learned:**
- skills.sh has NO manual submission process — repos are listed automatically once anyone installs them via the `skills` CLI (telemetry-driven leaderboard). "Adding" a skill = driving CLI installs, not filling out a form.
- skills.sh's CLI discovers skills by scanning well-known container dirs (skills/, .claude/skills/, .agents/skills/, etc.) with a recursive fallback; the 3 stratos-* dirs are found via the fallback.
- xcode-skills/ skills were never exposed on skills.sh because the directory was never committed — it is local-only personal reference.

---

### Entry 12: Cross-Skill Audit Against Xcode 27 Skills (2026-07-25)

**Problem:** Audit of Apple's Xcode 27 Beta 4 skills (`swiftui-specialist`, `swiftui-whats-new-27`) revealed contradictions and outdated patterns in `stratos-swiftui/`.

**Fixes applied to stratos-swiftui/SKILL.md:**

1. **Pattern 2 — `@MainActor` on `@Observable` class:** Added `@MainActor` to `UserViewModel` for Swift 6 strict concurrency safety. Observable classes used in views must run on the main actor.

2. **Pattern 4 — `@Entry` macro replacement:** Replaced manual `EnvironmentKey` boilerplate with the `@Entry` macro — Apple's canonical approach since iOS 18/macOS 15.

3. **Pattern 5 — Soft-deprecated API replacements:**
   - `.foregroundColor(.white)` → `.foregroundStyle(.white)`
   - `.cornerRadius(8)` → `.clipShape(RoundedRectangle(cornerRadius: 8))`

4. **Rejection criteria:** Added entry rejecting conditional `.if()` view modifier extensions — Apple explicitly warns against this pattern.

5. **SDK 27 note:** Added compatibility note about `@State` property wrapper → macro migration.

6. **Core Principles:** Added `@Animatable` macro mention.

7. **Pattern 2 — `@Observable` + `Equatable`:** Added guidance note on combining `@Observable` with `Equatable` conformance.

**Fixes applied to stratos-swiftui/references/LAYERS.md:**

1. Replaced manual `EnvironmentKey` boilerplate with `@Entry` macro
2. Replaced 3× `.foregroundColor()` → `.foregroundStyle()`
3. Replaced 3× `.cornerRadius()` → `.clipShape(RoundedRectangle(cornerRadius:))`

**Source used:**
Apple's Xcode 27 Beta 4 skills extracted from:
```
/Applications/Xcode-27.0.0-Beta.4.app/Contents/PlugIns/IDEIntelligenceChat.framework/Versions/A/Resources/
```
Specifically: `swiftui-specialist` (`dataflow.md`, `modifiers.md`, `soft-deprecated-apis.md`) and `swiftui-whats-new-27` (`state-macro.md`).

**What we learned:**
- Apple's `@Entry` macro (iOS 18+) makes manual `EnvironmentKey` boilerplate legacy — treat `@Entry` as the default
- `@Observable` classes used in views MUST be marked `@MainActor` for Swift 6 concurrency safety
- `.foregroundColor()` and `.cornerRadius()` are soft-deprecated; `foregroundStyle()` and `clipShape(RoundedRectangle(...))` are the replacements
- Apple explicitly rejects `.if()` conditional modifier extensions — this belongs in Stratos's rejection criteria
- `@State` migrated from property wrapper to macro in SDK 27 — reordering init assignments is the WRONG fix
- The `.packaged` and `.idechatprompttemplate` formats inside Xcode's skill bundles are plain UTF-8 markdown, not binary formats

---

### Entry 1: Initial Setup (2025-05-12)

**What we did:**
1. Created GitHub repository `peterfriese/Stratos` (private)
2. Initialized git repo with a simple README
3. Created directory structure for three skills

**What we learned:**
- The `npx skills add` command installs from GitHub repo root
- Option A (sub-skills in single repo) is the best approach - allows independent discovery while keeping brand cohesive
- Luca.tools supports `--skill` flag for installing specific subdirectories

---

### Entry 2: Skill Creation

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

### Entry 3: Validation Script

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

### Entry 4: Bug Fix - Multiline YAML Parsing (2025-05-12)

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

### Entry 5: Documentation Structure

**What we did:**
1. Renamed `docs/README.md` → `docs/JOURNAL.md`
2. Created `docs/DEVELOPMENT.md` with guidelines for future work

**What we learned:**
- Clear separation between "what happened" (JOURNAL) vs "how to do things" (DEVELOPMENT) follows the same principles we teach
- Always document learnings immediately - don't rely on memory

---

### Entry 6: Deduplication (2025-05-12)

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

### Entry 7: Enhancement with Modern Patterns (2025-05-12)

**Problem:** Skills needed to be updated with modern Swift/SwiftUI best practices while maintaining orthogonality.

**Enhancements Applied:**

**stratos-swiftui/SKILL.md** (SwiftUI-specific):
- Added Observable model pattern (@Observable model objects with @State in views)
- Enhanced Style Protocols with proper animation (value-based animations)
- Added Preview usage examples with #Preview
- Added Accessibility considerations (labelled buttons for VoiceOver)
- Maintained focus on SwiftUI-only patterns (views, modifiers, styles, environment)

**stratos-swift/SKILL.md** (Swift-specific):
- Enhanced Actor patterns: State isolation after await (check → await → store)
- Added Structured Concurrency: Task Groups over unstructured tasks
- Enhanced Sendable usage: Natural conformance vs justified @unchecked Sendable
- Added comprehensive async error handling patterns
- Maintained focus on Swift-only patterns (actors, concurrency, APIs, libraries)

**Core Principle Maintained:**
- Both skills reference stratos-core for Progressive Disclosure methodology
- No duplication of core methodology - each skill contains only domain-specific implementation
- Strict orthogonality: SwiftUI skill contains NO Swift API examples, Swift skill contains NO SwiftUI examples

**Verification:**
```
stratos-core:   271 → 271 lines (unchanged - core methodology)
stratos-swiftui: 216 → 357 lines (+141 lines - SwiftUI enhancements)
stratos-swift:   286 → 400 lines (+114 lines - Swift enhancements)
```

**What we learned:**
- Maintaining orthogonality leads to cleaner, more focused skills
- Modern Swift/SwiftUI patterns enhance the practical utility of the skills
- Clear domain boundaries make skills easier to use and understand
- Referencing core methodology keeps the single source of truth principle intact
- Enhancements should stay within each skill's domain to preserve orthogonality

---

### Entry 8: Fix Duplicate Pattern (2025-05-12)

**Problem:** Duplicate pattern section in stratos-swiftui/SKILL.md:
- Two sections labeled "Pattern 3: EnvironmentKey for Themes"
- Incorrect subsequent pattern numbering due to duplication and misnumbering

**Fix applied:**
1. Removed the duplicate "Pattern 3: EnvironmentKey for Themes" section
2. Renumbered all subsequent patterns correctly:
   - Pattern 1: The Container View (unchanged)
   - Pattern 2: The Observable Model (unchanged)
   - Pattern 2: The Modifier Chain → Pattern 3: The Modifier Chain
   - Pattern 3: EnvironmentKey for Themes → Pattern 4: EnvironmentKey for Themes
   - Pattern 4: Style Protocols for Deep Customization → Pattern 5: Style Protocols for Deep Customization
   - Pattern 5: Preview Usage → Pattern 6: Preview Usage
   - Pattern 6: Accessibility Considerations → Pattern 7: Accessibility Considerations

**Verification:**
```
stratos-swiftui: 357 → 316 lines (-41 lines - removed duplicate)
Pattern numbering: 1→7 (all correct and sequential)
```

**What we learned:**
- Duplicate sections can cause cascading numbering errors
- Pattern-based organization requires careful maintenance when adding/removing sections
- Automated checks for pattern numbering can help prevent such issues
- Keeping skills focused on their domain (SwiftUI-only) makes them easier to review and maintain

---

### Entry 9: WWDC Alignment Discovery (2025-05-12)

**What we did:**
1. Reviewed WWDC 2022-10059: "The craft of SwiftUI API design: Progressive disclosure"
2. Compared video's principles against Stratos skills methodology

**Discovery:**
The video is essentially a canonical explanation of Progressive Disclosure that Apple uses internally for SwiftUI API design. It aligns nearly perfectly with stratos-core:

- **Call Site First** - "To make code feel great to use, we have to look at it from the call site"
- **Consider Common Use Cases** → Design for Troposphere first
- **Intelligent Defaults** → Avoid Init-Bloat
- **Compose, Don't Enumerate** → Rejects Boolean/String traps

**Alignment scores:**
- stratos-core: 95% (video IS the canonical source)
- stratos-swiftui: 80% (all examples are SwiftUI-specific)
- stratos-swift: 40% (general principles only)

**Decision:**
Added video to "Further Reading" sections in stratos-core and stratos-swiftui. Did NOT add to stratos-swift since video examples are UI-focused.

**What we learned:**
- Independent creation is a complete copyright defense - Stratos skills were built without reference to the video
- Progressive Disclosure is a general UX/HCI principle, not Apple IP
- Validated Stratos methodology from authoritative source (Apple SwiftUI team)

---

### Entry 10: Swift Craft 2025 - Doug Gregor Talk (2025-05-12)

**What we did:**
1. Reviewed Swift Craft 2025 keynote: "On Progressive Disclosure in Swift" by Doug Gregor (Swift Core Team)
2. Compared against Stratos skills

**Discovery:**
Doug Gregor explains how Swift itself applies Progressive Disclosure as a language design principle:
- Layer 1: Strings, Arrays, Dictionaries
- Layer 2: Optionals, Closures
- Layer 3: Generics, Concurrency

Case studies: Typed Throws, Non-Copyable Types, "Approachable Concurrency" vision.

**Alignment scores:**
- stratos-core: 90% (language PD aligns with API PD)
- stratos-swift: 85% (mentions Typed Throws, Non-Copyable, Concurrency evolution)
- stratos-swiftui: 60% (language-focused, not UI-specific)

**Key difference from WWDC:**
- WWDC: Progressive Disclosure for API design (SwiftUI)
- Doug: Progressive Disclosure for language design (Swift)

**Decision:**
Added to stratos-core and stratos-swift (not stratos-swiftui - language focus).

**What we learned:**
- More technical than WWDC video - good for explaining *why* Swift follows these principles
- "Approachable Concurrency" vision document is relevant to stratos-swift concurrency patterns
- Two videos now provide complementary perspectives on the same principle

---

## Current Structure

```
Stratos/
├── LICENSE                    # Apache 2.0
├── CONTRIBUTING.md           # Contribution guidelines
├── README.md                  # Project overview
├── AGENTS.md                  # Development guidance for AI agents
├── stratos-core/
│   └── SKILL.md               # Core methodology (v1.0)
├── stratos-swiftui/
│   ├── SKILL.md               # SwiftUI skill (v1.0)
│   └── references/
│       └── LAYERS.md         # Detailed layer guidance
├── stratos-swift/
│   ├── SKILL.md               # Swift skill (v1.0)
│   └── references/
│       └── LAYERS.md         # Detailed layer guidance
├── docs/
│   └── JOURNAL.md            # Implementation journey
└── scripts/
    └── validate-skills.swift # Validation script
```

---

## Future Work

- [ ] Run evals comparing orthogonal vs embedded stratos-core
- [ ] Add example code to references
- [ ] Create Swift package for common utilities
- [ ] Consider adding TypeScript/React skill following same pattern
- [ ] Publish to SkillRegistry for broader discovery

---

### Entry 11: Launch Preparation (2025-05-12)

**What we did:**
1. Downloaded hero image from Pexels (Half Dome star trails by Robert Hacker)
2. Created 3 icon design options for each skill (Option A, B, C)
3. Added Apache 2.0 LICENSE file
4. Created CONTRIBUTING.md with guidelines
5. Updated README.md with hero image, badges, and acknowledgments
6. Updated AGENTS.md with proper assets structure
7. Bumped all skills to version 1.0

**File structure created:**
```
assets/
├── hero.jpg                    # Pexels hero image
├── option-a-stratos-core.svg   # Option A design (used)
├── option-b-stratos-core.svg   # Option B design
├── option-c-stratos-core.svg   # Option C design
... (similar for swift and swiftui)
stratos-core/assets/
├── icon.png                    # Primary icon (512x512)
├── icon.svg                    # Primary icon (vector)
├── icon-option-b.png
└── icon-option-c.png
... (similar for swift and swiftui)
```

**Icon design options:**
- **Option A**: Gradient "S" monogram with atmosphere layers (blue→purple gradient, dark sky background with stars)
- **Option B**: Ascending wave layers representing Troposphere→Thermosphere with gradient path
- **Option C**: Minimalist glow effect with vertical line and curve

**What we learned:**
- rsync or curl can download Pexels images directly
- rsvg-convert converts SVG to PNG at any resolution
- Three design options give good comparison for visual identity
- Apache 2.0 is a good license for open source libraries
- Hero images should be high-res (2400px width) for README display

**Decision:** Removed artwork before launch (2025-05-12) — decided to launch without it for simplicity.

---

## Notes

- Each SKILL.md includes "See Also" sections linking to related skills
- References are designed to be loaded on-demand (progressive disclosure)
- Validation script uses Swift as per user preference for Swift community alignment
- Always document learnings in JOURNAL.md when making changes
