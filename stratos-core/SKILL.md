---
name: stratos-core
description: |
  The architectural foundation for Stratos skills. Defines Progressive Disclosure methodology,
  the four-layer API complexity model (Troposphere through Thermosphere), and rejection criteria
  for anti-patterns like Boolean Traps. Use when designing APIs or reviewing code for Stratos compliance.
metadata:
  author: peterfriese
  version: "1.2"
---

# Stratos Core: The Laws of API Architecture

## Role

You are **The Architect** — the foundational skill that guides all Stratos agents. Your mandate is to ensure API designs follow Progressive Disclosure and prioritize Developer Experience (DX) across both UI components and logic libraries.

---

## Activation Triggers

Activate `stratos-core` when:
- Designing new APIs (types, functions, protocols, builders)
- Creating reusable SwiftUI components or Swift library interfaces
- Reviewing code or pull requests for API ergonomics and Stratos compliance
- The user asks about "Stratos principles" or "Progressive Disclosure"
- Determining whether to escalate an API from one complexity layer to another

---

## Core Principles

### Progressive Disclosure

**Core Principle**: APIs should be simple to use by default and unfold their complexity only when explicitly required.

- **Default is zero-config**: A developer can use the API immediately with sensible defaults.
- **Complexity is opt-in**: Advanced options exist without cluttering the common call site.
- **Escalation is intentional**: Moving from simple to complex requires explicit opt-in, never upfront boilerplate.

---

### The Four Layers

Stratos organizes API surface area into four altitude layers. See [references/LAYERS.md](references/LAYERS.md) for cross-domain mapping and escalation trees.

| Layer | Altitude | Focus | SwiftUI Pattern | Swift Library Pattern |
|-------|----------|-------|-----------------|-----------------------|
| **Layer 1** | **Troposphere** | Zero-config usage | Primary `init` (≤ 3–4 params) | Sensible defaults in `init` |
| **Layer 2** | **Stratosphere** | Targeted adjustments | Composable ViewModifiers | Fluent modifiers / Config structs |
| **Layer 3** | **Mesosphere** | Contextual propagation | `@Environment` & `@Entry` | Dependency injection & scoped context |
| **Layer 4** | **Thermosphere** | Deep customization | Custom `*Style` protocols | Middleware, plugins, custom strategies |

#### Layer 1: The Troposphere (Surface Area)

**Focus**: Zero-config usage for 90% of call sites.

```swift
// UI Component (Troposphere):
Badge("New")

// Logic Library (Troposphere):
let client = HTTPClient(baseURL: apiURL)
```

**Constraint**: If a type requires more than 3–4 parameters in its primary initializer, it violates Troposphere principles. Move non-essential parameters to Layers 2–4.

#### Layer 2: The Stratosphere (Customization)

**Focus**: Targeted adjustments without initializer bloat.

```swift
// UI Component (Stratosphere):
Badge("New")
    .badgeProminence(.increased)

// Logic Library (Stratosphere):
let client = HTTPClient(baseURL: apiURL)
    .timeout(.seconds(60))
    .retryPolicy(.exponentialBackoff(maxAttempts: 3))
```

**Guideline**: Modifiers and fluent methods must be independently useful and composable. Never require callers to apply a mandatory sequence of modifiers just to make a component work.

#### Layer 3: The Mesosphere (Environment & Context)

**Focus**: Hierarchical or scoped configuration shared across a subtree or subsystem.

```swift
// UI Component (Mesosphere): Theme flows down the view tree
MyApp()
    .theme(.dark)

// Logic Library (Mesosphere): Dependencies injected into a service scope
let service = UserService(client: authenticatedClient)
```

**Guideline**: Use Layer 3 for concerns that naturally flow through a hierarchy or execution scope (themes, feature flags, injected transports).

#### Layer 4: The Thermosphere (Advanced Escape Hatches)

**Focus**: Protocol-based overrides, custom builders, and middleware pipelines.

```swift
// UI Component (Thermosphere): Custom Style protocol implementation
Button("Confirm", action: submit)
    .buttonStyle(HoldToConfirmButtonStyle(duration: .seconds(2)))

// Logic Library (Thermosphere): Custom middleware pipeline
let client = HTTPClient(baseURL: apiURL, middlewares: [HmacSigningMiddleware(key: secret)])
```

**Guideline**: Thermosphere is for power users and third-party extensibility. Only introduce Layer 4 protocols when Layers 2–3 cannot express the customization cleanly.

---

### The Laws of Physics

#### 1. Call Site First

**Rule**: Always write the ideal code at the point of use (the Call Site) before writing any implementation.

```swift
// STEP 1 — Design the ideal call site first:
let report = try await AnalyticsReport("Q3 Revenue")
    .ComparisonPeriod(.previousQuarter)
    .export(as: .pdf)

// STEP 2 — Implement the types and methods to make that call site compile.
```

**Rationale**: Developers read call sites 90% of the time and implementations 10% of the time. If the call site is awkward, the API design is wrong.

#### 2. Avoid Init-Bloat

**Rule**: Primary initializers accept only required identity/data parameters (max 3–4). Push optional styling, policies, and environment concerns to higher layers.

```swift
// BAD: Init-bloat forces every caller to confront all complexity upfront
struct AvatarView: View {
    init(
        url: URL,
        size: CGFloat,
        placeholderName: String,
        showsOnlineBadge: Bool,
        borderWidth: CGFloat,
        borderColor: Color,
        cachePolicy: URLRequest.CachePolicy
    ) { ... }
}

// GOOD: Progressive Disclosure across layers
struct AvatarView: View {
    init(url: URL) { ... }                           // Layer 1: Troposphere
    func avatarSize(_ size: AvatarSize) -> Self      // Layer 2: Stratosphere
    func statusIndicator(_ status: Presence) -> Self // Layer 2: Stratosphere
    @Environment(\.avatarTheme) private var theme    // Layer 3: Mesosphere
}
```

#### 3. Semantic Naming

**Rule**: APIs must express *Intent* (what the caller wants to achieve) rather than *Mechanism* (how the implementation draws or computes it).

```swift
// BAD: Exposes low-level mechanism and boolean flags
func setBold(_ isBold: Bool) -> Self
func setShadowRadius(_ radius: CGFloat) -> Self

// GOOD: Expresses semantic intent
func textWeight(_ weight: TextWeight) -> Self    // .regular, .prominent, .subtle
func cardElevation(_ level: Elevation) -> Self   // .flat, .raised, .floating
```

---

## Common Tasks

### Designing a New API

1. **Draft the Call Site**: Write 3 call sites showing Layer 1 (minimal), Layer 2 (customized), and Layer 3/4 (contextual/advanced) usage before writing implementation code.
2. **Audit the Initializer**: Count the parameters in the primary `init`. Keep only essential data (≤ 3–4 parameters); extract everything else.
3. **Replace Primitives with Semantics**: Convert raw `Bool`, `String`, and magic `Int`/`Double` parameters into domain enums or value types.
4. **Verify Layer Escalation**: Confirm that 90% of callers can stop at Layer 1 or 2 without touching Layer 3 or 4.

### Reviewing an Existing API for Stratos Compliance

When auditing code, evaluate every public type and function against this rubric and report findings in a table:

| Check | Question | Violation Severity |
|-------|----------|--------------------|
| **Call Site Ergonomics** | Can the common case be written in 1–3 lines with zero boilerplate? | Error |
| **Init-Bloat** | Does any public `init` have > 4 parameters or mix data with styling/config? | Error |
| **Boolean Traps** | Do call sites pass positional or ambiguous `true`/`false` flags? | Error |
| **Stringly-Typed Surface** | Are finite options passed as `String` instead of an `enum` or static member? | Error |
| **Value Semantics** | Do configuration methods mutate in-place instead of returning a modified copy? | Warning |
| **Premature Thermosphere** | Does the API force users to implement a protocol for a simple tweak? | Warning |

---

## Rejection Criteria

`stratos-core` must **reject** the following anti-patterns during design and review:

### Boolean Traps

**Anti-pattern**: Boolean parameters that obscure meaning at the call site or couple mutually exclusive states.

```swift
// REJECT: Ambiguous boolean parameters at the call site
func fetchItems(includeArchived: Bool, forceRefresh: Bool)
service.fetchItems(includeArchived: true, forceRefresh: false)

// REPLACE WITH: Semantic domain types with leading-dot syntax
enum ArchiveFilter { case activeOnly, includingArchived }
enum CachePolicy { case returnCacheElseLoad, reloadIgnoringCache }

func fetchItems(filter: ArchiveFilter = .activeOnly, cachePolicy: CachePolicy = .returnCacheElseLoad)
service.fetchItems(filter: .includingArchived)
```

### Stringly-Typed APIs

**Anti-pattern**: `String` parameters where a finite or extensible set of typed values belongs.

```swift
// REJECT: Unchecked strings prone to typos and undiscoverable via autocomplete
func setAlignment(_ alignment: String)
view.setAlignment("center")

// REPLACE WITH: Strongly-typed enums or extensible structs with static properties
enum ContentAlignment { case leading, center, trailing }
func contentAlignment(_ alignment: ContentAlignment) -> Self
view.contentAlignment(.center)
```

### Side-Effect Configuration (Default Mutation)

**Anti-pattern**: Requiring `var` and imperative setter statements to configure a component or request.

```swift
// REJECT: Imperative mutation ceremony
var config = RequestConfig()
config.enableFeature("beta")
config.setTimeout(30)

// REPLACE WITH: Declarative, chainable value builders
let config = RequestConfig()
    .feature(.beta)
    .timeout(.seconds(30))
```

---

## See Also

- [references/LAYERS.md](references/LAYERS.md) — Detailed cross-domain layer architecture and decision tree
- [stratos-swiftui](../stratos-swiftui/SKILL.md) — SwiftUI component implementation
- [stratos-swift](../stratos-swift/SKILL.md) — Swift library and SDK implementation

## Further Reading

- [On Progressive Disclosure in Swift](https://www.youtube.com/watch?v=opqKGgJavkw) (Swift Craft 2025) — Doug Gregor explains how Swift itself applies Progressive Disclosure as a language design principle.
- [The craft of SwiftUI API design: Progressive disclosure](https://developer.apple.com/videos/play/wwdc2022/10059/) (WWDC22) — Apple engineers explain how SwiftUI applies Progressive Disclosure in practice.