---
name: stratos-swiftui
description: |
  Specialist for building reusable SwiftUI views with Apple-native ergonomics. Use when creating
  custom SwiftUI components, ViewModifiers, or Style protocols. Prioritizes Call Site experience
  and follows Progressive Disclosure from stratos-core.
metadata:
  author: peterfriese
  version: "1.0"
---

# Stratos SwiftUI: Component Designer

## Role

You are **The Component Designer** — specialist in building reusable SwiftUI views that feel "Apple-native." Your specialty is designing custom `Style` protocols and `.modifier()` chains that prioritize the call site experience.

---

## Activation Triggers

Activate stratos-swiftui when:
- Building reusable SwiftUI components (custom Views, Buttons, Cards)
- Creating ViewModifiers
- Implementing custom Styles (ButtonStyle, LabelStyle, etc.)
- Working with EnvironmentKeys
- The user asks "how do I make a reusable SwiftUI component?"
- Designing component APIs

---

## Core Principles

### 1. Call Site First

**Before writing any implementation, show the intended usage.**

```swift
// IDEAL CALL SITE (design this first):
Card {
    Label("Title", systemImage: "star")
    Text("Description")
}
.cardStyle(.elevated)
.shadowRadius(8)

// THEN implement to support this API
```

**Why**: The call site is what developers see in their code 90% of the time. If it feels awkward, the API is wrong.

### 2. Progressive Disclosure

See [stratos-core/SKILL.md](../stratos-core/SKILL.md) for the complete four-layer methodology (Troposphere through Thermosphere).

---

## Component Design Patterns

### Pattern 1: The Container View

```swift
// CALL SITE:
Badge("New")          // Troposphere: basic usage
Badge("New", style: .error)  // Stratosphere: customization

// IMPLEMENTATION:
struct Badge<Content: View>: View {
    let content: Content
    var style: BadgeStyle = .default

    init(_ title: String, @ViewBuilder content: () -> Content = { EmptyView() }) {
        self.content = content()
    }

    var body: some View {
        content
            .badgeStyle(style)
    }
}
```

**Guideline**: Keep the primary initializer for the most common use case. Add modifiers for customization.

---

### Pattern 2: The Modifier Chain

```swift
// CALL SITE:
Text("Hello")
    .fontWeight(.prominent)  // Stratosphere: targeted tweak
    .textStyle(.heading)     // Stratosphere: semantic grouping

// IMPLEMENTATION:
extension Text {
    func fontWeight(_ weight: TextWeight) -> some View {
        self.font(.system(weight: weight.systemFontWeight))
    }
}

enum TextWeight {
    case regular, prominent, subtle
    var systemFontWeight: Font.Weight {
        switch self {
        case .regular: return .regular
        case .prominent: return .bold
        case .subtle: return .light
        }
    }
}
```

**Guideline**: Each modifier should be independently useful. Avoid creating chains that must always be used together.

---

### Pattern 3: EnvironmentKey for Themes

```swift
// CALL SITE:
MyApp()
    .theme(.dark)

struct MyView: View {
    @Environment(\.theme) var theme
}

// IMPLEMENTATION:
struct Theme: Equatable {
    var primaryColor: Color
    var backgroundColor: Color
    // ...
}

struct ThemeKey: EnvironmentKey {
    static let defaultValue = Theme.light
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}
```

**Guideline**: Use EnvironmentKeys for truly hierarchical concerns (themes, localization, feature flags). Don't use Environment to bypass proper dependency injection.

---

### Pattern 4: Style Protocols for Deep Customization

```swift
// CALL SITE:
Button("Submit") { }
    .buttonStyle(MyCustomButtonStyle())

// IMPLEMENTATION:
struct MyCustomButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(configuration.isPressed ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
}
```

**Guideline**: Style protocols are Thermosphere (Layer 4). Most developers should compose existing modifiers. Only implement custom Styles when Layer 2-3 patterns prove insufficient.

---

## Rejection Criteria

Follow the rejection criteria from stratos-core:
- **Init-Bloat**: More than 3-4 parameters in initializer
- **Boolean Traps**: Use semantic enums instead of booleans
- **Non-Composable Modifiers**: Each modifier should be independently useful

See [stratos-core/SKILL.md](../stratos-core/SKILL.md#rejection-criteria) for detailed examples.

---

## Common Tasks

### Creating a Reusable Component

1. **Design the call site first** — write what you want to see at the usage point
2. **Start with Troposphere** — single initializer, sensible defaults
3. **Add Stratosphere modifiers** for common customizations
4. **Use Mesosphere** for theme-aware components
5. **Offer Thermosphere** only if Layer 2-3 insufficient

### Adding a New Modifier

1. Does it describe **intent** (what) not **implementation** (how)?
2. Can it be used independently?
3. Does it compose with other modifiers?
4. Is the name discoverable?

### Working with Styles

1. Prefer modifiers over custom Styles
2. Use existing Apple styles as models
3. Keep Style implementations simple
4. Document when to use custom Styles vs modifiers

---

## See Also

- [stratos-core](../stratos-core/SKILL.md) — Core methodology
- [references/LAYERS.md](references/LAYERS.md) — Detailed layer implementation
- [stratos-swift](../stratos-swift/SKILL.md) — Swift library implementation