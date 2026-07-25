# SwiftUI Layer Reference

Detailed implementation guidance for each of the four Stratos layers in SwiftUI contexts.

---

## Layer 1: Troposphere — zero-config defaults

### Implementation guidelines

Troposphere-level components should work with zero configuration:

```swift
// Minimal viable component
struct StatusBadge: View {
    let status: Status

    var body: some View {
        Text(status.displayName)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.color.opacity(0.2))
            .foregroundStyle(status.color)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

// Usage: StatusBadge(status: .active) — works immediately
```

### What belongs here

- Required data (the "what")
- Sensible defaults that work in 90% of cases
- Single initializer with max 3-4 parameters

### What doesn't belong

- Optional styling options
- Configuration variants
- Theme-dependent values (→ Layer 3)

---

## Layer 2: Stratosphere — targeted adjustments

### Implementation guidelines

Stratosphere uses ViewModifiers for targeted customization:

```swift
extension View {
    func badgeStyle(_ style: BadgeStyle) -> some View {
        self.modifier(BadgeStyleModifier(style: style))
    }

    func shadowRadius(_ radius: CGFloat) -> some View {
        self.shadow(radius: radius)
    }
}
```

### Modifier design rules

1. **Independent**: Each modifier should work alone
2. **Composable**: Order shouldn't matter (unless it does—document it)
3. **Discoverable**: Name should match SwiftUI conventions
4. **Intent over Implementation**: Name the effect, not the method

### Examples of good modifiers

```swift
// Good: Describes what developer wants
.fontWeight(.prominent)
.cardElevation(.raised)
.statusColor(.success)

// Bad: Describes how it's implemented
.setBold(true)
.shadowRadius(8)
.backgroundColor(.blue)
```

---

## Layer 3: Mesosphere — environment configuration

### When to use EnvironmentKeys

Use Environment for:
- **Themes**: colors, typography, spacing
- **Localization**: text direction, locale-specific formatting
- **Feature flags**: beta features, experimental APIs
- **User preferences**: accessibility settings, display modes

Don't use Environment for:
- **Dependency injection** (use protocols)
- **Ephemeral state** (use @State)
- **Cross-cutting concerns** (too broad)

### Implementation pattern

```swift
extension EnvironmentValues {
    @Entry var theme: Theme = Theme.light
}
```

The `@Entry` macro (iOS 18+/macOS 15+) replaces the manual `EnvironmentKey` boilerplate. No need for a separate key struct, computed getter/setter, or default value wrapper.

### Reading from environment

```swift
struct MyComponent: View {
    @Environment(\.theme) var theme

    var body: some View {
        Text("Hello")
            .foregroundStyle(theme.primaryColor)
            .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius))
    }
}
```

---

## Layer 4: Thermosphere — Style Protocols

### When to use style protocols

Thermosphere is for **power users** who need full control. Most developers should stop at Layer 2-3.

Use Style protocols when:
- The component has multiple customizable aspects that are conceptually grouped
- You want to enable "themes" that affect many properties at once
- The customization surface is too large for individual modifiers

### ButtonStyle example

```swift
struct ProminentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                configuration.isPressed
                    ? Color.blue.opacity(0.8)
                    : Color.blue
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
```

### LabelStyle example

```swift
struct IconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            configuration.icon
                .font(.title3)
            configuration.title
                .font(.body)
        }
    }
}
```

### Style composition

```swift
// Use with modifier
Button("Hello") { }
    .buttonStyle(ProminentButtonStyle())

// Or apply at the view hierarchy level
Label("Title", systemImage: "star")
    .labelStyle(IconLabelStyle())
```

---

## Layer escalation decision tree

```
Is there a default that works for 90% of cases?
├─ NO → Start at Layer 1 (Troposphere)
└─ YES → Can developers customize common aspects?
          ├─ NO → Layer 1 is sufficient
          └─ YES → Do customizations vary by context/hierarchy?
                    ├─ NO → Layer 2 (Stratosphere) via modifiers
                    └─ YES → Do customizations need theming?
                              ├─ NO → Layer 2
                              └─ YES → Layer 3 (Mesosphere) via Environment
```

**Only escalate to Layer 4 (Thermosphere) when:**
- Layer 2-3 patterns have been proven insufficient
- The use case genuinely requires protocol-based customization
- You're building a system meant for third-party extension

---

## Anti-patterns

### Over-engineering

```swift
// BAD: Creating a Style when a simple modifier would suffice
struct SimpleTextStyle: TextStyle { ... }  // Overkill

// GOOD: Just use .fontWeight()
Text("Hello").fontWeight(.prominent)
```

### Environment abuse

```swift
// BAD: Using Environment for dependency injection
struct NetworkClient: EnvironmentKey {
    static let defaultValue: NetworkClientProtocol = RealClient()
}

// GOOD: Use protocols for DI
protocol NetworkClientProtocol { ... }
```

### Modifier explosion

```swift
// BAD: Too many modifiers that should be grouped
Text("Hello")
    .fontSize(14)
    .fontWeight(.bold)
    .fontFamily(.system)
    .lineSpacing(1.5)
    .letterSpacing(0.5)

// GOOD: Use existing SwiftUI .font() modifier
Text("Hello")
    .font(.system(size: 14, weight: .bold, design: .default))
```

---

## Further reading

- Apple's [Styling Views](https://developer.apple.com/documentation/swiftui/view-styling) documentation
- [SwiftUI Style Protocols](https://developer.apple.com/documentation/swiftui/buttonstyle) guide
- [EnvironmentValues](https://developer.apple.com/documentation/swiftui/environmentvalues) pattern