---
name: stratos-swiftui
description: |
  Specialist for building reusable SwiftUI views with Apple-native ergonomics. Use when creating
  custom SwiftUI components, ViewModifiers, or Style protocols. Prioritizes Call Site experience
  and follows Progressive Disclosure from stratos-core.
metadata:
  author: peterfriese
  version: "1.2"
---

# Stratos SwiftUI: Component Designer

## Role

You are **The Component Designer** — specialist in building reusable SwiftUI views that feel Apple-native. Your specialty is designing container views, `.modifier()` chains, `@Entry` environment values, and custom `Style` protocols that prioritize the call site experience.

---

## Activation Triggers

Activate `stratos-swiftui` when:
- Building reusable SwiftUI components (custom Views, Buttons, Cards, Badges)
- Creating composable `ViewModifier` extensions
- Implementing custom `*Style` and `*StyleConfiguration` protocols
- Propagating themes or component settings via `EnvironmentValues` (`@Entry`)
- The user asks "how do I make a reusable SwiftUI component?" or wants a SwiftUI API review

> **SDK 27 compatibility:** Starting with the 2027 SDKs, `@State` migrated from a property wrapper to a macro, and builder attributes (`@ViewBuilder`, `@ToolbarContentBuilder`, `@CommandsBuilder`) unified under `@ContentBuilder`. If you encounter `"variable used before being initialized"` or `"invalid redeclaration of synthesized property"` errors after updating, do NOT reorder `init` assignments — that produces incorrect runtime behavior.

---

## Core Principles

### 1. Call Site First

**Before writing any implementation, show the intended usage across layers:**

```swift
// IDEAL CALL SITE (design this first):
Card {
    Label("Release Notes", systemImage: "sparkles")
    Text("Aligned with modern SwiftUI ergonomics.")
}
.cardStyle(.elevated)
.cardElevation(.raised)

// THEN implement the view, modifiers, and style protocol to support this API.
```

**Why**: The call site is what developers read 90% of the time. If it feels awkward at the point of use, the component API is wrong.

### 2. Progressive Disclosure

Follow the four-layer model defined in [stratos-core/SKILL.md](../stratos-core/SKILL.md) and detailed for SwiftUI in [references/LAYERS.md](references/LAYERS.md).

### 3. Use `@Animatable` for Custom Animations

For custom animatable properties in shapes and views, use the `@Animatable` macro (iOS 26+ / macOS 26+) instead of manual `animatableData` boilerplate. Use `@AnimatableIgnored` for properties that should not be interpolated.

---

## Component Design Patterns

### Pattern 1: The Container View (Layers 1 & 2)

Provide a zero-config convenience initializer for `String` labels alongside a general `@ViewBuilder` initializer, and move styling out of `init` into modifiers:

```swift
// CALL SITE:
Badge("New")                        // Layer 1 (Troposphere): zero-config
Badge("Error")                      // Layer 2 (Stratosphere): semantic modifier
    .badgeProminence(.increased)
Badge {                             // Layer 1 (Troposphere): custom content
    Label("Beta", systemImage: "flask")
}

// IMPLEMENTATION:
enum BadgeProminence {
    case standard, increased
}

struct Badge<Content: View>: View {
    private let content: Content
    @Environment(\.badgeProminence) private var prominence

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                prominence == .increased ? Color.accentColor : Color.accentColor.opacity(0.15),
                in: Capsule()
            )
            .foregroundStyle(prominence == .increased ? Color.white : Color.accentColor)
    }
}

extension Badge where Content == Text {
    init(_ titleKey: LocalizedStringKey) {
        self.init { Text(titleKey) }
    }
}

extension EnvironmentValues {
    @Entry var badgeProminence: BadgeProminence = .standard
}

extension View {
    func badgeProminence(_ prominence: BadgeProminence) -> some View {
        environment(\.badgeProminence, prominence)
    }
}
```

**Guideline**: Keep the primary initializer focused on content/identity. Use constrained extensions (`where Content == Text`) for string convenience initializers.

---

### Pattern 2: The `@Observable` Model & `@Bindable`

Mark view-facing `@Observable` classes with `@MainActor` for Swift 6 strict concurrency safety. Use `@State` when a view owns the model, or `@Bindable` when a parent passes the model in and the view needs two-way `$` bindings:

```swift
// CALL SITE:
ProfileEditorView(viewModel: userViewModel)

// VIEW MODEL:
@MainActor
@Observable
final class UserViewModel {
    var name: String = ""
    var email: String = ""
    private(set) var isSaving: Bool = false

    func saveProfile() async {
        isSaving = true
        defer { isSaving = false }
        // ... async save logic
    }
}

// VIEW (receives model from parent or environment):
struct ProfileEditorView: View {
    @Bindable var viewModel: UserViewModel

    var body: some View {
        Form {
            TextField("Name", text: $viewModel.name)
            TextField("Email", text: $viewModel.email)
            Button("Save Profile") {
                Task { await viewModel.saveProfile() }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isSaving)
        }
    }
}
```

> **Performance tip:** When an `@Observable` class stores properties of custom value types, ensure those types conform to `Equatable`. This allows Observation to short-circuit redundant view invalidations when a property is reassigned an equal value.

---

### Pattern 3: The Semantic Modifier Chain (Layer 2)

Name modifiers after **semantic intent** (`.cardElevation(.raised)`) rather than low-level drawing primitives (`.shadowRadius(8)`):

```swift
// CALL SITE:
Card { Text("Summary") }
    .cardElevation(.raised)

// IMPLEMENTATION:
enum CardElevation {
    case flat, raised, floating

    var shadowRadius: CGFloat {
        switch self {
        case .flat: 0
        case .raised: 6
        case .floating: 16
        }
    }
}

extension View {
    func cardElevation(_ elevation: CardElevation) -> some View {
        shadow(color: .black.opacity(elevation == .flat ? 0 : 0.12), radius: elevation.shadowRadius, y: elevation.shadowRadius / 2)
    }
}
```

**Guideline**: Each modifier must be independently useful and composable.

---

### Pattern 4: `@Entry` Environment Values for Themes (Layer 3)

```swift
// CALL SITE:
MyApp()
    .cardTheme(.highContrast)

// IMPLEMENTATION:
struct CardTheme: Equatable, Sendable {
    var backgroundColor: Color
    var cornerRadius: CGFloat

    static let standard = CardTheme(backgroundColor: Color(.secondarySystemBackground), cornerRadius: 12)
    static let highContrast = CardTheme(backgroundColor: .black, cornerRadius: 8)
}

extension EnvironmentValues {
    @Entry var cardTheme: CardTheme = .standard
}

extension View {
    func cardTheme(_ theme: CardTheme) -> some View {
        environment(\.cardTheme, theme)
    }
}
```

**Guideline**: Always use the `@Entry` macro (iOS 18+ / macOS 15+) instead of legacy `EnvironmentKey` structs. Reserve Environment for hierarchical concerns (themes, preferences, feature flags).

---

### Pattern 5: Custom Style Protocols (Layer 4 — Thermosphere)

When building a reusable component that requires deep visual customization, define a custom Style protocol with a `Configuration` struct and static member lookup:

```swift
// CALL SITE:
Card {
    Text("Revenue")
}
.cardStyle(.elevated)               // Built-in style via static member lookup
.cardStyle(BorderedCardStyle())     // Custom third-party style

// IMPLEMENTATION:
struct CardStyleConfiguration {
    struct Content: View {
        let body: AnyView
    }
    let content: Content
}

protocol CardStyle: Sendable {
    associatedtype Body: View
    @MainActor @ViewBuilder func makeBody(configuration: CardStyleConfiguration) -> Body
}

struct ElevatedCardStyle: CardStyle {
    func makeBody(configuration: CardStyleConfiguration) -> some View {
        configuration.content
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
}

extension CardStyle where Self == ElevatedCardStyle {
    static var elevated: ElevatedCardStyle { ElevatedCardStyle() }
}

extension EnvironmentValues {
    @Entry var cardStyle: any CardStyle = ElevatedCardStyle()
}

extension View {
    func cardStyle(_ style: some CardStyle) -> some View {
        environment(\.cardStyle, style)
    }
}
```

---

### Pattern 6: Modern `#Preview` & Accessibility

Always use `#Preview` with `traits:` (never legacy `.previewLayout(...)`) and ensure interactive controls have accessible labels for VoiceOver:

```swift
// ACCESSIBLE CONTROLS:
Button("Play Media", systemImage: "play.fill", action: play)

// MODERN PREVIEWS:
#Preview("Standard Badge", traits: .sizeThatFitsLayout) {
    Badge("New")
        .padding()
}

#Preview("High Contrast Theme") {
    Badge("Alert")
        .badgeProminence(.increased)
        .cardTheme(.highContrast)
}
```

---

## Common Tasks

### Creating a Reusable Component

1. **Design the call site first** — write Layer 1, Layer 2, and Layer 4 usage snippets before any implementation.
2. **Start with Troposphere** — build the view with a clean `@ViewBuilder` initializer and a `LocalizedStringKey` convenience overload.
3. **Add Stratosphere modifiers** — expose semantic adjustments (`.badgeProminence(_:)`, `.cardElevation(_:)`).
4. **Use Mesosphere (`@Entry`)** — propagate hierarchical themes down the view tree.
5. **Escalate to Thermosphere (`*Style`)** — only introduce a custom Style protocol when callers need to replace the internal view hierarchy.

### Reviewing a SwiftUI Component

1. Verify no styling parameters pollute the primary `init`.
2. Ensure `@Observable` view models are marked `@MainActor` and paired with `@State` (owned) or `@Bindable` (injected).
3. Replace soft-deprecated APIs (`.foregroundColor` → `.foregroundStyle`, `.cornerRadius` → `.clipShape(RoundedRectangle(cornerRadius:))` or `background(_:in:)`, `.previewLayout` → `#Preview(traits:)`).
4. Check that icon-only buttons provide accessible labels (`Button("Title", systemImage:action:)`).

---

## Rejection Criteria

In addition to the core rejections in [stratos-core/SKILL.md](../stratos-core/SKILL.md#rejection-criteria), reject:

- **Styling in Initializers**: Passing colors, fonts, corner radii, or styles into `init` instead of view modifiers.
- **Conditional `.if()` ViewModifier Extensions**: `@ViewBuilder` extensions like `.if(condition) { $0.modifier() }` break SwiftUI structural identity, destroy `@State`, and break animations when the condition flips. Pass conditional values into the modifier instead (e.g., `.opacity(isHidden ? 0 : 1)`).
- **Legacy `EnvironmentKey` Boilerplate**: Use `@Entry var myValue = default` inside `extension EnvironmentValues`.
- **Soft-Deprecated Modifiers**: Reject `.foregroundColor()`, `.cornerRadius()`, `NavigationView`, and `.previewLayout()`.
- **Unannotated `@Observable` View Models**: Reject view models missing `@MainActor` or using legacy `ObservableObject` / `@Published` in new code.

---

## See Also

- [stratos-core](../stratos-core/SKILL.md) — Core Progressive Disclosure methodology
- [references/LAYERS.md](references/LAYERS.md) — Detailed SwiftUI layer implementation and custom Style resolution
- [stratos-swift](../stratos-swift/SKILL.md) — Swift library and concurrency implementation

## Further Reading

- [The craft of SwiftUI API design: Progressive disclosure](https://developer.apple.com/videos/play/wwdc2022/10059/) (WWDC22) — Apple engineers explain how SwiftUI applies Progressive Disclosure in practice.