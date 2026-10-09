# SwiftUI Layer Reference

Detailed implementation guidance for each of the four Stratos layers in SwiftUI contexts.

---

## Layer 1: Troposphere — Zero-Config Defaults

### Implementation Guidelines

Troposphere-level components work immediately with zero configuration:

```swift
struct StatusBadge: View {
    let status: Status

    var body: some View {
        Text(status.displayName)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.color.opacity(0.2), in: RoundedRectangle(cornerRadius: 6))
            .foregroundStyle(status.color)
    }
}

// Usage: StatusBadge(status: .active) — works immediately
```

### What Belongs Here

- Required data and identity (the "what")
- `@ViewBuilder` content closures and `LocalizedStringKey` convenience initializers
- Sensible defaults that work in 90% of cases
- Single primary initializer with at most 3–4 parameters

### What Doesn't Belong

- Optional visual styling (colors, padding, shadows)
- Configuration variants (→ Layer 2)
- Theme-dependent values (→ Layer 3)

---

## Layer 2: Stratosphere — Targeted Adjustments

### Implementation Guidelines

Stratosphere uses `ViewModifier` or `View` extensions for targeted, semantic customization:

```swift
enum CardElevation {
    case flat, raised, floating

    var radius: CGFloat {
        switch self {
        case .flat: 0
        case .raised: 6
        case .floating: 16
        }
    }
}

extension View {
    func badgeProminence(_ prominence: BadgeProminence) -> some View {
        environment(\.badgeProminence, prominence)
    }

    func cardElevation(_ elevation: CardElevation) -> some View {
        shadow(
            color: .black.opacity(elevation == .flat ? 0 : 0.12),
            radius: elevation.radius,
            y: elevation.radius / 2
        )
    }
}
```

### Modifier Design Rules

1. **Independent**: Each modifier works alone without requiring companion modifiers.
2. **Composable**: Applying multiple modifiers produces predictable, additive behavior.
3. **Discoverable**: Parameter types use enums or static members for leading-dot autocomplete.
4. **Intent over Implementation**: Name the semantic effect, not the drawing primitive.

```swift
// GOOD: Describes semantic intent
.badgeProminence(.prominent)
.cardElevation(.raised)
.statusTone(.warning)

// BAD: Exposes raw mechanism or boolean flags
.setBold(true)
.shadowRadius(8)
.backgroundColor(.blue)
```

---

## Layer 3: Mesosphere — Environment Configuration

### When to Use `EnvironmentValues` (`@Entry`)

Use Environment for:
- **Themes**: semantic color palettes, typography scales, corner radii
- **Component Policies**: badge prominence, control density, redaction reasons
- **Feature Flags & Preferences**: user display modes, layout direction

Do not use Environment for:
- **Ephemeral view state** (use `@State`)
- **Two-way model bindings** (use `@Bindable`)
- **Imperative service locators** where explicit protocol injection or `@Observable` models are clearer

### Implementation Pattern

```swift
extension EnvironmentValues {
    @Entry var theme: Theme = .light
}

extension View {
    func theme(_ theme: Theme) -> some View {
        environment(\.theme, theme)
    }
}
```

The `@Entry` macro (iOS 18+ / macOS 15+) replaces manual `EnvironmentKey` structs and getter/setter boilerplate.

### Reading from Environment

```swift
struct ThemedBanner: View {
    let title: LocalizedStringKey
    @Environment(\.theme) private var theme

    var body: some View {
        Text(title)
            .padding()
            .foregroundStyle(theme.primaryColor)
            .background(theme.surfaceColor, in: RoundedRectangle(cornerRadius: theme.cornerRadius))
    }
}
```

---

## Layer 4: Thermosphere — Style Protocols

### When to Use Style Protocols

Thermosphere is for **power users** who need full control over a component's structure and interaction states. Most callers should stop at Layers 1–3.

Use Style protocols when:
- A component has multiple sub-elements or interaction states (`isPressed`, `isExpanded`, `role`) that custom designs need to rearrange
- You want third-party consumers to create completely bespoke visual representations while keeping the component's accessibility and state machine intact

### Conforming to Built-In Apple Style Protocols

```swift
struct ProminentScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                configuration.isPressed ? Color.blue.opacity(0.8) : Color.blue,
                in: RoundedRectangle(cornerRadius: 10)
            )
            .foregroundStyle(.white)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == ProminentScaleButtonStyle {
    static var prominentScale: ProminentScaleButtonStyle { ProminentScaleButtonStyle() }
}
```

### Building a Complete Custom Style Protocol for Your Own Component

To wire a custom `CardStyle` inside your `Card` view, resolve the existential `any CardStyle` from the environment using a helper method that opens the existential into `some CardStyle`:

```swift
struct Card<Content: View>: View {
    private let content: Content
    @Environment(\.cardStyle) private var style

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        let configuration = CardStyleConfiguration(
            content: .init(body: AnyView(content))
        )
        AnyView(resolveStyle(style, configuration: configuration))
    }

    @MainActor
    private func resolveStyle<S: CardStyle>(
        _ style: S,
        configuration: CardStyleConfiguration
    ) -> some View {
        style.makeBody(configuration: configuration)
    }
}
```

---

## Layer Escalation Decision Tree

```
Does a zero-config default work for 90% of call sites?
├─ NO  → Refine Layer 1 (Troposphere) until only essential data is required
└─ YES → Do callers need to tweak individual instances?
          ├─ NO  → Stop at Layer 1
          └─ YES → Expose semantic modifiers in Layer 2 (Stratosphere)
                    │
                    └─ Should tweaks cascade down a view hierarchy?
                        ├─ NO  → Stop at Layer 2
                        └─ YES → Propagate via @Entry in Layer 3 (Mesosphere)
                                  │
                                  └─ Do power users need to replace internal layout/structure?
                                      ├─ NO  → Stop at Layer 3
                                      └─ YES → Define a *Style protocol in Layer 4 (Thermosphere)
```

---

## Anti-Patterns

### Over-Engineering (Premature Thermosphere)

```swift
// BAD: Creating a full Style protocol when a single semantic modifier suffices
protocol HeadingTextStyle { ... }

// GOOD: Use a semantic Layer 2 modifier
Text("Welcome").textRole(.heroTitle)
```

### Conditional `.if()` Modifier Trap

```swift
// BAD: Destroys view identity and state when `isHighlighted` toggles
Text("Status")
    .if(isHighlighted) { view in
        view.foregroundStyle(.red)
    }

// GOOD: Keep structural identity stable with inert/ternary values
Text("Status")
    .foregroundStyle(isHighlighted ? .red : .primary)
```

### Modifier Explosion

```swift
// BAD: Too many low-level modifiers that must always be chained together
Text("Title")
    .fontSize(14)
    .fontWeight(.bold)
    .lineSpacing(1.5)
    .letterSpacing(0.5)

// GOOD: Group cohesive typography tokens into a single semantic modifier or theme token
Text("Title")
    .textStyle(.captionProminent)
```

---

## Further Reading

- [Styling Views](https://developer.apple.com/documentation/swiftui/view-styling) — Apple Developer Documentation
- [ButtonStyle](https://developer.apple.com/documentation/swiftui/buttonstyle) — Apple Developer Documentation
- [EnvironmentValues](https://developer.apple.com/documentation/swiftui/environmentvalues) — Apple Developer Documentation