# Stratos Implementation Journal

A chronological record of building the Stratos skills - decisions, discoveries, and lessons learned.

---

## Implementation Journey

### Entry 15: Promptfoo Evaluation Suite & Multi-Model Benchmark (2026-10-08)

**What changed:**
- Created `feat/evals` branch off `main` after committing the `v1.2` skill and validation upgrades in 5 atomic commits.
- Built a [Promptfoo](https://www.promptfoo.dev/) evaluation harness in [`evals/`](../evals/README.md):
  - [`evals/promptfooconfig.yaml`](../evals/promptfooconfig.yaml): Configures a 3-way comparison matrix across `1. Baseline (No Skill)`, `2. Domain Skill Only (Standalone)`, and `3. Full Stratos (stratos-core + Domain Skill)` using `vertex:gemini-3-flash-preview` by default (plus `npm run eval:pro` for `vertex:gemini-3.1-pro-preview`).
  - [`evals/prompts/build-prompt.js`](../evals/prompts/build-prompt.js): Dynamically injects `SKILL.md` and `references/LAYERS.md` from the repository based on `vars.skill` and `vars.include_references`.
  - [`evals/assertions/stratos-assertions.js`](../evals/assertions/stratos-assertions.js): Deterministic JavaScript assertions checking uncommented Swift code blocks for `assertCallSiteFirst`, `assertNoInitBloat`, `assertModernSwiftUICode`, `assertModernObservationCode`, and `assertNoNSLockInCode`.
  - Test suites covering 9 scenarios (27 evaluations per run) across [`evals/tests/core.yaml`](../evals/tests/core.yaml), [`evals/tests/swiftui.yaml`](../evals/tests/swiftui.yaml), and [`evals/tests/swift.yaml`](../evals/tests/swift.yaml).
- Tightened **Call Site First** across all three `SKILL.md` files (requiring the very first Swift code block to show the call site before any type definitions) and added **Unlabelled Icon-Only Controls (Accessibility)** to `stratos-swiftui/SKILL.md` Rejection Criteria based on initial eval feedback.

**Benchmark results (`vertex:gemini-3-flash-preview`):**
- **Baseline (No Skill)**: `0 / 9` passed (avg score `0.52`) — endorsed `.if()` conditional modifier anti-pattern, used `NSLock` / `OSAllocatedUnfairLock` instead of `Mutex`, used untyped `throws`, omitted `@Entry`, and placed call sites last.
- **Domain Skill Only (Standalone)**: `9 / 9` passed (**100%**, avg score `1.00`).
- **Full Stratos (`stratos-core` + Domain Skill)**: `8 / 9` passed (`89%`, 9th at `0.97`, avg score `1.00`).

**What we learned:**
- Promptfoo custom JS prompt functions receive test variables via `vars` (`{ vars }`), not `test.metadata`.
- `gemini-2.5-flash` occasionally gets stuck in an infinite `| :---` Markdown table separator loop on rubric table prompts; `gemini-3-flash-preview`, `gemini-2.5-pro`, and `gemini-3.1-pro-preview` have zero table glitches, with `gemini-3-flash-preview` completing all 27 evaluations in 1m 18s.
- Deterministic anti-pattern assertions (`not-icontains`) must be scoped to uncommented ````swift` code blocks rather than full Markdown prose—otherwise models get penalized when explaining *why* they avoided `NSLock` or `ObservableObject`.
- Two rounds of read-only GitHub Copilot code review on PR #1 caught subtle edge cases in both our evaluation assertions and Swift code snippets:
  - Regex `init\(([^)]*)\)` truncates parameter lists containing closure types (`() -> Void`) or default initializers (`Color(.secondarySystemBackground)`); replacing it with a balanced-parenthesis scanner (`extractInitParameterLists`) properly inspects all parameters.
  - `assertCallSiteFirst` must include `enum`, `extension`, `func`, and `typealias` in its declaration detector and verify positive call-expression evidence so declaration-only blocks are never mistaken for call sites.
  - Public structs in Swift library examples (`StubHTTPTransport`) always need an explicit `public init(...)` because Swift's synthesized memberwise initializer is `internal` by default.

---

### Entry 14: Comprehensive Skill Audit, Validation Upgrade & v1.2 Modernization (2026-10-08)

**Problem:**
A full repository review across skill structure, validation tooling, documentation, and Swift/SwiftUI code examples uncovered several gaps:
1. **Validation gaps**: `scripts/validate-skills.swift` had a dead `stratos-universe/` path, didn't verify `name == skillName` (parent directory match), ignored `metadata.author` and `metadata.version`, didn't validate required section ordering (`Role` → `Activation Triggers` → `Core Principles` → `Common Tasks` → `Rejection Criteria` → `See Also`), and didn't check relative Markdown links.
2. **Structural asymmetry**: `stratos-core` lacked a `references/LAYERS.md` file and was missing the required `Common Tasks` section, while `stratos-swift/SKILL.md` (404 lines) exceeded the ~250–350 line target in `AGENTS.md`.
3. **Domain orthogonality & code bugs**:
   - `stratos-core/SKILL.md` used SwiftUI-only examples for Layers 1–4 and had invalid Swift declaration syntax (`func weight(_: .prominent)`, `func setAlignment("center")`).
   - `stratos-swiftui/SKILL.md` had a broken `Badge` initializer (`title` parameter was ignored, `style` was passed in `init` violating Layer 1/2), a call site mismatch in `ProfileView` (missing `@Bindable`), a non-existent `.font(.system(weight:))` overload, deprecated `.previewLayout(...)` modifiers, a self-contradiction on `.shadowRadius(8)` vs `.cardElevation(.raised)`, and no example of defining a custom `*Style` protocol.
   - `stratos-swift/SKILL.md` had a non-compiling `UserRepository.fetchUser` (`try await` in a non-throwing function without reentrancy deduplication), invalid `@unchecked Sendable` attribute syntax with legacy `NSLock`, a rigid 4-tuple `RequestBuilder` that couldn't reorder or omit components, a mutating `sort(by:)` call inside a non-mutating `sorted()` extension, non-existent `@stable`/`@unstable` attributes, and missing `: Sendable` conformances on DI protocols in `references/LAYERS.md`.

**Fixes applied:**
1. **Upgraded `scripts/validate-skills.swift`**:
   - Fixed `SkillManifest` path and accurate `wc -l` line counting.
   - Added validation for `name == skillName`, `metadata.author`, `metadata.version`, required section presence and order, 350-line warning / 500-line error thresholds, and relative Markdown link existence across `SKILL.md` and `references/*.md`.
2. **Overhauled `stratos-core` (v1.2)**:
   - Added cross-domain UI + SDK examples for all four layers, fixed Swift syntax, added `Common Tasks` with a structured **API Review Rubric**, and created `stratos-core/references/LAYERS.md` with a cross-domain mapping table, decision tree, and before/after refactoring case study.
3. **Overhauled `stratos-swiftui` (v1.2)**:
   - Fixed `Badge` with a `@ViewBuilder` primary init, `where Content == Text` convenience init, and `.badgeProminence(_:)` environment modifier.
   - Updated `ProfileEditorView` to demonstrate `@Bindable` alongside `@MainActor @Observable`.
   - Replaced `.shadowRadius(8)` with semantic `.cardElevation(.raised)` across both `SKILL.md` and `references/LAYERS.md`.
   - Added a complete custom `CardStyle` + `CardStyleConfiguration` + existential resolution pattern for Layer 4.
   - Replaced deprecated `.previewLayout(.sizeThatFits)` with `#Preview("...", traits: .sizeThatFitsLayout)`.
4. **Overhauled `stratos-swift` (v1.2)**:
   - Brought `SKILL.md` from 404 lines down to 289 lines.
   - Added Swift 6 **Typed Throws** (`throws(TokenError)`), **`Mutex`** from `Synchronization`, and **`~Copyable`** transaction handles.
   - Unified `UserRepository` with in-flight `Task` deduplication for true actor reentrancy safety.
   - Rewrote `RequestBuilder` using a `RequestComponent` enum with `buildExpression`, `buildOptional`, and `buildEither`.
   - Added `: Sendable` to all DI and middleware protocols in `references/LAYERS.md` and fixed its inverted Layer Escalation Decision Tree.
5. **Documentation sync**:
   - Reordered `docs/JOURNAL.md` into strict reverse chronological order (Entries 14 → 1).
   - Removed stale `assets/` references from `CONTRIBUTING.md` and updated `README.md` and `AGENTS.md` for v1.2.

**What we learned:**
- Validation scripts must enforce the exact rules documented in `AGENTS.md` and `CONTRIBUTING.md` (especially section ordering, metadata fields, and relative links)—otherwise drift is inevitable.
- Code snippets inside AI agent skills are copied verbatim by downstream models; every snippet (even small 5-line examples) must use valid Swift 6 syntax and compile cleanly.
- Teaching Progressive Disclosure in `stratos-core` works best when paired side-by-side with both a UI example (SwiftUI) and a non-UI example (Swift SDK) at every layer.

---

### Entry 13: Distribution on skills.sh (2026-07-31)

**What changed:**
- Verified Stratos is already listed on skills.sh (skills.sh/peterfriese/stratos) — no manual submission exists; listing happens automatically via anonymous telemetry when users run `npx skills add peterfriese/Stratos`. Repo page shows 3 skills, 18 installs.
- Added the official skills.sh badge to README.md header: `[![skills.sh](https://skills.sh/b/peterfriese/Stratos)](https://skills.sh/peterfriese/Stratos)` (commit bf28a51, "docs: add skills.sh badge to README").
- Restyled the License and Version shields.io badges to dark flat style (labelColor=000000, color=0a0a0a) so all three header badges match skills.sh's branded badge.
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
- shields.io badges can closely match skills.sh's custom badge by setting `labelColor=000000` and `color=0a0a0a` (same hex values skills.sh uses); the only element that cannot be reproduced is the Vercel triangle logo.

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

### Entry 11: Launch Preparation (2025-05-12)

**What we did:**
1. Downloaded hero image from Pexels (Half Dome star trails by Robert Hacker)
2. Created 3 icon design options for each skill (Option A, B, C)
3. Added Apache 2.0 LICENSE file
4. Created CONTRIBUTING.md with guidelines
5. Updated README.md with hero image, badges, and acknowledgments
6. Updated AGENTS.md with proper assets structure
7. Bumped all skills to version 1.0

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

### Entry 8: Fix Duplicate Pattern (2025-05-12)

**Problem:** Duplicate pattern section in stratos-swiftui/SKILL.md:
- Two sections labeled "Pattern 3: EnvironmentKey for Themes"
- Incorrect subsequent pattern numbering due to duplication and misnumbering

**Fix applied:**
1. Removed the duplicate "Pattern 3: EnvironmentKey for Themes" section
2. Renumbered all subsequent patterns01→07 sequentially.

**What we learned:**
- Duplicate sections can cause cascading numbering errors
- Pattern-based organization requires careful maintenance when adding/removing sections
- Keeping skills focused on their domain (SwiftUI-only) makes them easier to review and maintain

---

### Entry 7: Enhancement with Modern Patterns (2025-05-12)

**Problem:** Skills needed to be updated with modern Swift/SwiftUI best practices while maintaining orthogonality.

**Enhancements Applied:**
- **stratos-swiftui/SKILL.md**: Added `@Observable` model pattern, Style protocols with value-based animations, `#Preview`, and accessibility considerations.
- **stratos-swift/SKILL.md**: Enhanced Actor patterns, Structured Concurrency (`TaskGroup`), `Sendable` usage, and async error handling.

**What we learned:**
- Maintaining orthogonality leads to cleaner, more focused skills
- Modern Swift/SwiftUI patterns enhance the practical utility of the skills
- Referencing core methodology keeps the single source of truth principle intact

---

### Entry 6: Deduplication (2025-05-12)

**Problem:** Significant duplication across skills ("When to Apply" vs "Activation Triggers", abbreviated PD tables, Call Site First, Boolean Traps).

**Fix applied:**
1. Removed "When to Apply" section from stratos-core (redundant with Activation Triggers)
2. Replaced abbreviated PD + layers tables in swiftui/swift with references to stratos-core
3. Replaced duplicate rejection criteria in swiftui/swift with references to stratos-core

**What we learned:**
- Orthogonal skills should reference, not repeat
- Each skill should keep only what makes it unique (swiftui: patterns, swift: concurrency/builders, core: methodology)

---

### Entry 5: Documentation Structure (2025-05-12)

**What we did:**
1. Renamed `docs/README.md` → `docs/JOURNAL.md`
2. Established clear separation between chronological change logs (`docs/JOURNAL.md`) and contributor/agent guidelines (`CONTRIBUTING.md` and `AGENTS.md`).

**What we learned:**
- Clear separation between "what happened" (JOURNAL) vs "how to do things" (CONTRIBUTING / AGENTS) follows the same principles we teach
- Always document learnings immediately - don't rely on memory

---

### Entry 4: Bug Fix - Multiline YAML Parsing (2025-05-12)

**Problem:** Validation script reported descriptions as "1 char" even though they were 200+ characters.

**Root cause:** The regex `(\w+):\s*(.*)` only captured the first line after the colon. Multiline YAML uses `|` or `>` indicators which continue on subsequent indented lines.

**Fix applied:**
- Rewrote `parseFrontmatter()` to detect multiline indicators (`|` or `>`) and collect all subsequent indented lines.

**What we learned:**
- Always test YAML parsing with actual multiline content
- Validation scripts should verify content, not just structure

---

### Entry 3: Validation Script (2025-05-12)

**What we did:**
Created `scripts/validate-skills.swift` to validate YAML frontmatter format, name format, description length, and flat `references/` structure.

**What we learned:**
- The spec's 64-char name limit and 1024-char description limit are strict requirements.

---

### Entry 2: Skill Creation (2025-05-12)

**What we did:**
1. Created `stratos-core/SKILL.md` (Progressive Disclosure, Four Layers, Laws of Physics, Rejection Criteria)
2. Created `stratos-swiftui/SKILL.md` (Component Designer role, patterns, rejection criteria)
3. Created `stratos-swift/SKILL.md` (SDK Engineer role, Swift 6 concurrency, Result-builders, library evolution)
4. Created `references/LAYERS.md` files for on-demand depth.

**What we learned:**
- agentskills.io spec itself follows progressive disclosure - this aligned perfectly with Stratos philosophy
- References should be one level deep (`references/LAYERS.md`, not deeper)

---

### Entry 1: Initial Setup (2025-05-12)

**What we did:**
1. Created GitHub repository `peterfriese/Stratos`
2. Initialized git repo with a simple README
3. Created directory structure for three skills

**What we learned:**
- The `npx skills add` command installs from GitHub repo root
- Sub-skills in a single repo allows independent discovery while keeping the brand cohesive

---

## Current Structure

```
Stratos/
├── LICENSE                    # Apache 2.0
├── CONTRIBUTING.md            # Contribution guidelines
├── README.md                  # Project overview
├── AGENTS.md                  # Development guidance for AI agents
├── opencode.example.jsonc     # Example OpenCode fleet config
├── .opencode/
│   └── agents/                # Chief of Staff & subagent definitions
├── stratos-core/
│   ├── SKILL.md               # Core methodology (v1.2)
│   └── references/
│       └── LAYERS.md          # Cross-domain layer reference
├── stratos-swiftui/
│   ├── SKILL.md               # SwiftUI skill (v1.2)
│   └── references/
│       └── LAYERS.md          # Detailed SwiftUI layer guidance
├── stratos-swift/
│   ├── SKILL.md               # Swift skill (v1.2)
│   └── references/
│       └── LAYERS.md          # Detailed Swift SDK layer guidance
├── docs/
│   └── JOURNAL.md             # Implementation journey
└── scripts/
    └── validate-skills.swift  # Validation script
```

---

## Future Work

- [ ] Run evals comparing orthogonal vs embedded stratos-core
- [ ] Create Swift package for common utilities
- [ ] Consider adding TypeScript/React skill following same pattern
