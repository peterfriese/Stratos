# Stratos Promptfoo Evaluation Suite

This directory contains the [Promptfoo](https://www.promptfoo.dev/) evaluation harness for measuring how effectively the **Stratos** skills (`stratos-core`, `stratos-swiftui`, and `stratos-swift`) improve AI agent code generation and API reviews.

---

## What It Evaluates

Every test case runs side-by-side across **three prompt configurations** defined in [`prompts/build-prompt.js`](prompts/build-prompt.js):

1. **`1. Baseline (No Skill)`** — Standard expert Swift/SwiftUI system prompt with no Stratos instructions.
2. **`2. Domain Skill Only (Standalone)`** — Loads only the target skill's `SKILL.md` (and `references/LAYERS.md` when `include_references: true`).
3. **`3. Full Stratos (stratos-core + Domain Skill)`** — Loads `stratos-core/SKILL.md` alongside the domain skill (`stratos-swiftui` or `stratos-swift`) to measure the impact of orthogonal skill composition.

### Test Suites (9 scenarios × 3 configurations = 27 evaluations)

| Suite | File | Scenarios Covered |
|-------|------|-------------------|
| **stratos-core** | [`tests/core.yaml`](tests/core.yaml) | 1. Refactoring an init-bloated type into Layers 1–4<br>2. Generating a structured API Review Rubric table<br>3. Mapping product requirements across Troposphere → Thermosphere |
| **stratos-swiftui** | [`tests/swiftui.yaml`](tests/swiftui.yaml) | 1. Reusable `CalloutView` with `@Entry` and custom `CalloutStyle`<br>2. `@MainActor @Observable` view model with `@Bindable` form bindings<br>3. Rejecting `.if()` conditional modifier, soft-deprecated APIs, and unlabelled icon buttons |
| **stratos-swift** | [`tests/swift.yaml`](tests/swift.yaml) | 1. Actor reentrancy safety with in-flight `Task` deduplication<br>2. Synchronous thread safety with Swift 6 `Mutex` and Typed Throws (`throws(QuotaError)`)<br>3. Flexible `@resultBuilder` DSL with `buildOptional` and semantic enums |

### Deterministic + LLM-Rubric Assertions

Each test combines fast, deterministic checks ([`assertions/stratos-assertions.js`](assertions/stratos-assertions.js), `icontains`, `not-icontains`, `regex`) with semantic grading (`llm-rubric`):
- **`assertCallSiteFirst`**: Verifies that the first Swift code block demonstrates call-site usage before target `struct`/`actor`/`class`/`protocol` implementations.
- **`assertNoInitBloat`**: Parses all uncommented Swift `init(...)` blocks and verifies none exceed 4 parameters.
- **Code-Scoped Anti-Pattern Guards** (`assertModernSwiftUICode`, `assertModernObservationCode`, `assertNoNSLockInCode`): Inspects uncommented ````swift` code blocks to reject `.foregroundColor(`, `.cornerRadius(`, `.previewLayout(`, legacy `EnvironmentKey`, `ObservableObject`, `@ObservedObject`, and `NSLock`.

---

## Benchmark Results (`vertex:gemini-3-flash-preview`)

| Prompt Configuration | Scenarios Passed | Average Score | Delta vs. Baseline |
| :--- | :---: | :---: | :---: |
| **1. Baseline (No Skill)** | 0 / 9 (0%) | 0.52 | — |
| **2. Domain Skill Only (Standalone)** | **9 / 9 (100%)** | **1.00** | **+0.48 (+100% pass)** |
| **3. Full Stratos (`stratos-core` + Domain Skill)** | **8 / 9 (89%)** | **1.00** (`0.997`) | **+0.48 (+89% pass)** |

---

## Quick Start

### 1. Run the default evaluation suite (`vertex:gemini-3-flash-preview`)

By default, [`promptfooconfig.yaml`](promptfooconfig.yaml) uses Vertex AI (`vertex:gemini-3-flash-preview`) via your local Google Cloud Application Default Credentials (`GOOGLE_APPLICATION_CREDENTIALS` / `GOOGLE_CLOUD_PROJECT`).

```bash
cd evals
npm run eval
```

Or run a single skill domain or frontier model:

```bash
npm run eval:core     # stratos-core scenarios only
npm run eval:swiftui  # stratos-swiftui scenarios only
npm run eval:swift    # stratos-swift scenarios only
npm run eval:pro      # Evaluate against vertex:gemini-3.1-pro-preview
```

### 2. Override the model provider on the CLI

```bash
# Evaluate with Gemini 2.5 Pro
npx promptfoo@latest eval -c promptfooconfig.yaml -p vertex:gemini-2.5-pro

# Evaluate with Claude Sonnet
npx promptfoo@latest eval -c promptfooconfig.yaml -p anthropic:messages:claude-sonnet-4-5
```

### 3. View interactive comparison matrix

```bash
npm run eval:view
```
