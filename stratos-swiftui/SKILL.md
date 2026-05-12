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

### Pattern 2: The Observable Model

```swift
// CALL SITE (in view):
ProfileView(userViewModel)

// VIEW MODEL:
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

---

### Pattern 3: The Modifier Chain

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

### Pattern 4: EnvironmentKey for Themes

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

// Convenience modifier:
extension View {
    func theme(_ theme: Theme) -> some View {
        environment(\.theme, theme)
    }
}
```

**Guideline**: Use EnvironmentKeys for truly hierarchical concerns (themes, localization, feature flags). Don't use Environment to bypass proper dependency injection.

---

### Pattern 5: Style Protocols for Deep Customization

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
            .foregroundColor(.white)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
```

**Guideline**: Style protocols are Thermosphere (Layer 4). Most developers should compose existing modifiers. Only implement custom Styles when Layer 2-3 patterns prove insufficient.

---

### Pattern 6: Preview Usage

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

### Pattern 7: Accessibility Considerations

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

## Further Reading

- [The craft of SwiftUI API design: Progressive disclosure](https://developer.apple.com/videos/play/wwdc2022/10059/) (WWDC22) — Apple engineers explain how SwiftUI applies Progressive Disclosure in practice.