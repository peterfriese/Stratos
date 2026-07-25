---
name: stratos-swiftui
description: |
  Specialist for building reusable SwiftUI views with Apple-native ergonomics. Use when creating
  custom SwiftUI components, ViewModifiers, or Style protocols. Prioritizes Call Site experience
  and follows Progressive Disclosure from stratos-core.
metadata:
  author: peterfriese
  version: "1.1"
---

# Stratos SwiftUI: Component Designer

## Role

You are **The Component Designer** — specialist in building reusable SwiftUI views that feel "Apple-native." Your specialty is designing custom `Style` protocols and `.modifier()` chains that prioritize the call site experience.

---

## Activation triggers

Activate stratos-swiftui when:
- Building reusable SwiftUI components (custom Views, Buttons, Cards)
- Creating ViewModifiers
- Implementing custom Styles (ButtonStyle, LabelStyle, etc.)
- Working with EnvironmentKeys
- The user asks "how do I make a reusable SwiftUI component?"
- Designing component APIs

> **SDK 27 compatibility:** Starting with the 2027 SDKs, `@State` migrated from a property wrapper to a macro. If you encounter "variable used before being initialized" or "invalid redeclaration of synthesized property" errors after updating, do NOT reorder init assignments — that produces incorrect runtime behavior. See Apple's `swiftui-whats-new-27` skill for migration guidance.

---

## Core principles

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

### 3. Use @Animatable for custom animations

For custom animatable properties in shapes and views, use the `@Animatable` macro (iOS 26+/macOS 26+) instead of manual `AnimatableValues`. It reduces boilerplate and supports property-level clamping/normalization.

---

## Component design patterns

### Pattern 1: The container view

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

### Pattern 2: The Observable model

```swift
// CALL SITE (in view):
ProfileView(userViewModel)

// VIEW MODEL:
// Mark @MainActor for Swift 6 strict concurrency safety — views read model properties on the main actor.
@MainActor
@Observable
class UserViewModel {
    var name: String = ""
    var email: String = ""
    var isLoading: Bool = false
    
    func updateProfile() {
        // Update properties - views observing this will update automatically
        isLoading = true
        // ... update logic
        isLoading = false
    }
}

// VIEW:
struct ProfileView: View {
    @State private var viewModel = UserViewModel()
    
    var body: some View {
        VStack(spacing: 16) {
            TextField("Name", text: $viewModel.name)
                .textFieldStyle(.roundedBorder)
            TextField("Email", text: $viewModel.email)
                .textFieldStyle(.roundedBorder)
            if viewModel.isLoading {
                ProgressView()
            }
            Button("Update Profile") {
                viewModel.updateProfile()
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoading)
        }
        .padding()
    }
}
```

**Guideline**: Use `@Observable` for model objects that need to be observed across views. Combine with `@State` in views for optimal performance.

> When an `@Observable` class has properties of custom types, ensure those types conform to `Equatable`. This allows SwiftUI to short-circuit redundant view invalidations when the property hasn't actually changed. Without `Equatable`, every property assignment triggers invalidation even if the value is the same.

---

### Pattern 3: The modifier chain

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

### Pattern 4: EnvironmentKey for themes

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

extension EnvironmentValues {
    @Entry var theme: Theme = Theme.light
}

// Convenience modifier:
extension View {
    func theme(_ theme: Theme) -> some View {
        environment(\.theme, theme)
    }
}
```

**Guideline**: Use EnvironmentKeys for truly hierarchical concerns (themes, localization, feature flags). Don't use Environment to bypass proper dependency injection.

---

### Pattern 5: Style protocols for deep customization

```swift
// CALL SITE:
Button("Submit") { }
    .buttonStyle(MyCustomButtonStyle())

// IMPLEMENTATION:
struct MyCustomButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(
                configuration.isPressed 
                    ? Color.gray.opacity(0.8) 
                    : Color.blue
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
```

**Guideline**: Style protocols are Thermosphere (Layer 4). Most developers should compose existing modifiers. Only implement custom Styles when Layer 2-3 patterns prove insufficient.

---

### Pattern 6: Preview usage

```swift
// CALL SITE (in preview file):
#Preview {
    Badge("New")
        .previewLayout(.sizeThatFits)
        .padding()
}

// OR with environment:
#Preview {
    Badge("New")
        .environment(\.theme, Theme.dark)
        .previewLayout(.device)
}
```

**Guideline**: Use `#Preview` for SwiftUI previews instead of legacy PreviewProvider. Test different configurations and layouts.

---

### Pattern 7: Accessibility considerations

```swift
// CALL SITE:
// Instead of:
Button(action: play) { Image(systemName: "play.fill") }

// Better (labelled for VoiceOver):
Button("Play Media", systemImage: "play.fill", action: play)

// Or with custom label:
Button(action: play) {
    Label("Play Media", systemImage: "play.fill")
}
```

**Guideline**: Always provide accessible labels for VoiceOver users. Prefer labelled buttons over icon-only buttons.

---

## Rejection criteria

Follow the rejection criteria from stratos-core:
- **Init-Bloat**: More than 3-4 parameters in initializer
- **Boolean Traps**: Use semantic enums instead of booleans
- **Non-Composable Modifiers**: Each modifier should be independently useful
- **Conditional `.if()` view modifier extensions** — Extensions that use `@ViewBuilder` to conditionally apply modifiers (`.if(condition) { $0.modifier() }`) break structural identity, reset `@State`, and disable animations when the condition toggles. Use ternary expressions in modifier arguments instead (e.g., `.foregroundStyle(isHighlighted ? .red : .primary)`).

See [stratos-core/SKILL.md](../stratos-core/SKILL.md#rejection-criteria) for detailed examples.

---

## Common tasks

### Creating a reusable component

1. **Design the call site first** — write what you want to see at the usage point
2. **Start with Troposphere** — single initializer, sensible defaults
3. **Add Stratosphere modifiers** for common customizations
4. **Use Mesosphere** for theme-aware components
5. **Offer Thermosphere** only if Layer 2-3 insufficient

### Adding a new modifier

1. Does it describe **intent** (what) not **implementation** (how)?
2. Can it be used independently?
3. Does it compose with other modifiers?
4. Is the name discoverable?

### Working with styles

1. Prefer modifiers over custom Styles
2. Use existing Apple styles as models
3. Keep Style implementations simple
4. Document when to use custom Styles vs modifiers

---

## See also

- [stratos-core](../stratos-core/SKILL.md) — Core methodology
- [references/LAYERS.md](references/LAYERS.md) — Detailed layer implementation
- [stratos-swift](../stratos-swift/SKILL.md) — Swift library implementation

## Further reading

- [The craft of SwiftUI API design: Progressive disclosure](https://developer.apple.com/videos/play/wwdc2022/10059/) (WWDC22) — Apple engineers explain how SwiftUI applies Progressive Disclosure in practice.