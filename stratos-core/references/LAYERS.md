# Stratos Architecture Layer Reference

Detailed architectural guidance for mapping API complexity across the four Stratos layers, regardless of whether you are building a declarative UI component or a logic SDK.

---

## Cross-Domain Layer Mapping

Every feature in an API belongs to one of four altitude layers based on **how frequently callers need it** and **how broadly it affects the system**:

| Dimension | Layer 1: Troposphere | Layer 2: Stratosphere | Layer 3: Mesosphere | Layer 4: Thermosphere |
|-----------|----------------------|-----------------------|---------------------|-----------------------|
| **Target Audience** | 90% of callers | 60% of callers | App/Module Architects | Power users & plugin authors |
| **Configuration Cost** | Zero (sensible defaults) | 1-line modifier or config | 1-line at root / DI scope | Custom type / protocol conformance |
| **Scope of Effect** | Single instance | Single instance | Subtree / Subsystem | Full behavioral or visual override |
| **SwiftUI Mechanism** | Primary `init` | ViewModifier / `extension View` | `@Environment` + `@Entry` | `*Style` & `*StyleConfiguration` |
| **Swift SDK Mechanism** | Primary `init` with defaults | Fluent builder / Config struct | Protocol DI / `@TaskLocal` | Middleware / Strategy protocols |

---

## Layer-by-Layer Design Rules

### Layer 1: Troposphere — Essential Identity Only

Ask: *"What is the absolute minimum information required for this object to exist and do its job?"*

- **Include**: Primary data model, title/label, primary action, or target endpoint.
- **Exclude**: Colors, fonts, timeouts, retry counts, caching flags, delegates, and loggers.
- **Rule of 3–4**: If your primary initializer has more than 4 parameters, classify each parameter as either **Identity** (keep in Layer 1), **Instance Tweak** (move to Layer 2), or **Environment/Context** (move to Layer 3).

```swift
// BEFORE: Everything crammed into Layer 1
public init(
    title: String,
    subtitle: String? = nil,
    icon: Image? = nil,
    tintColor: Color = .accentColor,
    cornerRadius: CGFloat = 12,
    isDismissible: Bool = true,
    analyticsTracker: AnalyticsTracking = DefaultTracker.shared
)

// AFTER: Split by altitude
public init(_ title: String, subtitle: String? = nil) // Layer 1: Identity
public func bannerIcon(_ icon: Image) -> Self         // Layer 2: Instance tweak
public func dismissBehavior(_ behavior: DismissBehavior) -> Self // Layer 2: Semantic enum
// tintColor & cornerRadius → Layer 3 (@Environment(\.bannerTheme))
// analyticsTracker → Layer 3 (@Environment(\.analytics) or Service DI)
```

---

### Layer 2: Stratosphere — Composable Instance Adjustments

Layer 2 lets callers refine a single call site without paying for features they don't use.

1. **Order Independence**: Calling `.a().b()` should produce the same result as `.b().a()` whenever possible. If order matters (such as layout padding before background), make the composition visual and predictable.
2. **Orthogonality**: One modifier should adjust one semantic concept. Avoid "combo" modifiers like `.configureStyleAndTimeout(style:timeout:)`.
3. **Leading-Dot Ergonomics**: Parameter types should be dedicated enums or structs with static members so Xcode autocomplete reveals all valid choices after typing `.`.

---

### Layer 3: Mesosphere — Scoped & Hierarchical Context

Layer 3 avoids "prop drilling" (passing the same configuration or dependency through 10 intermediate initializers).

- **When to escalate from Layer 2 to Layer 3**:
  - A caller is applying the exact same Layer 2 modifier to 5+ instances across a screen or module.
  - A cross-cutting policy (theme, locale, auth token provider, telemetry sink) needs to be swapped for an entire view hierarchy, request scope, or unit test suite.
- **Guardrail**: Always provide a sensible default value in Layer 3 so that Layer 1 call sites still work out-of-the-box without requiring a root provider.

---

### Layer 4: Thermosphere — Open Extension Points

Layer 4 turns fixed components into extensible platforms.

- **Structure of a Thermosphere Escape Hatch**:
  1. A **Configuration** value type exposing the component's semantic parts and state (e.g., `label`, `isPressed`, or `request`, `context`).
  2. A **Protocol** with a single primary requirement that transforms the configuration (e.g., `makeBody(configuration:)` or `intercept(_:context:)`).
  3. **Static Member Lookup** on the protocol so built-in implementations feel like Layer 2 at the call site (`.cardStyle(.elevated)`), while custom implementations seamlessly plug into the same slot (`.cardStyle(GlassmorphicCardStyle())`).

---

## Layer Escalation Decision Tree

Use this decision tree whenever someone proposes adding a new parameter or capability to an API:

```
Is this value required for the API to make sense at all?
├─ YES → Layer 1 (Troposphere: primary initializer parameter)
└─ NO (a sensible default exists for 90% of callers)
    │
    ├─ Does it change how a single instance behaves or looks?
    │   └─ YES → Layer 2 (Stratosphere: fluent modifier or config property)
    │
    ├─ Should it apply uniformly across a subtree, module, or test scope?
    │   └─ YES → Layer 3 (Mesosphere: @Environment / @TaskLocal / DI container)
    │
    └─ Does the caller need to replace the internal layout or execution pipeline?
        └─ YES → Layer 4 (Thermosphere: Style protocol / Middleware / Strategy)
```

---

## Refactoring Case Study: Before vs. After Stratos

### Before: Monolithic API

```swift
// Hard to read, boolean traps, stringly-typed mode, mandatory nil arguments
let uploader = FileUploader(
    fileURL: localFileURL,
    destinationBucket: "user-avatars",
    chunkSize: 5_242_880,
    compressBeforeUpload: true,
    compressionQuality: 0.8,
    encryptionMode: "AES256",
    onProgress: { percent in print(percent) },
    customTransport: nil
)
try await uploader.start()
```

### After: Layered Stratos API

```swift
// Layer 1 (Troposphere): Zero-config common case
try await FileUpload(from: localFileURL, to: .userAvatars)
    .send()

// Layer 2 (Stratosphere): Targeted semantic adjustments
try await FileUpload(from: localFileURL, to: .userAvatars)
    .compression(.jpeg(quality: 0.8))
    .encryption(.aes256)
    .onProgress { progress in
        print(progress.fractionCompleted)
    }
    .send()

// Layer 3 (Mesosphere): Custom transport injection for scoped / test contexts
let service = FileUploadService(transport: MockChunkedTransport())
try await service.upload(localFileURL, to: .userAvatars)

// Layer 4 (Thermosphere): Custom chunking/interceptor strategy for power users
try await FileUpload(from: localFileURL, to: .userAvatars)
    .uploadStrategy(AdaptiveMultistreamStrategy(maxConcurrentStreams: 4))
    .send()
```
