# SwiftUI Layer Reference

Detailed implementation guidance for each of the four Stratos layers in SwiftUI contexts.

---

## Layer 1: Troposphere — Zero-Config Defaults

### Implementation Guidelines

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
            .foregroundColor(status.color)
            .cornerRadius(4)
    }
}

// Usage: StatusBadge(status: .active) — works immediately
```

### What Belongs Here

- Required data (the "what")
- Sensible defaults that work in 90% of cases
- Single initializer with max 3-4 parameters

### What Doesn't Belong

- Optional styling options
- Configuration variants
- Theme-dependent values (→ Layer 3)

---

## Layer 2: Stratosphere — Targeted Adjustments

### Implementation Guidelines

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

### Modifier Design Rules

1. **Independent**: Each modifier should work alone
2. **Composable**: Order shouldn't matter (unless it does—document it)
3. **Discoverable**: Name should match SwiftUI conventions
4. **Intent over Implementation**: Name the effect, not the method

### Examples of Good Modifiers

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

## Layer 3: Mesosphere — Environment Configuration

### When to Use EnvironmentKeys

Use Environment for:
- **Themes**: colors, typography, spacing
- **Localization**: text direction, locale-specific formatting
- **Feature flags**: beta features, experimental APIs
- **User preferences**: accessibility settings, display modes

Don't use Environment for:
- **Dependency injection** (use protocols)
- **Ephemeral state** (use @State)
- **Cross-cutting concerns** (too broad)

### Implementation Pattern

```swift
// 1. Define the value
struct AppTheme: Equatable {
    var primaryColor: Color
    var cornerRadius: CGFloat
}

// 2. Define the key
struct ThemeKey: EnvironmentKey {
    static let defaultValue = AppTheme(
        primaryColor: .blue,
        cornerRadius: 8
    )
}

// 3. Add to EnvironmentValues
extension EnvironmentValues {
    var theme: AppTheme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// 4. Convenience modifier
extension View {
    func theme(_ theme: AppTheme) -> some View {
        environment(\.theme, theme)
    }
}
```

### Reading from Environment

```swift
struct MyComponent: View {
    @Environment(\.theme) var theme

    var body: some View {
        Text("Hello")
            .foregroundColor(theme.primaryColor)
            .cornerRadius(theme.cornerRadius)
    }
}
```

---

## Layer 4: Thermosphere — Style Protocols

### When to Use Style Protocols

Thermosphere is for **power users** who need full control. Most developers should stop at Layer 2-3.

Use Style protocols when:
- The component has multiple customizable aspects that are conceptually grouped
- You want to enable "themes" that affect many properties at once
- The customization surface is too large for individual modifiers

### ButtonStyle Example

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
            .foregroundColor(.white)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
```

### LabelStyle Example

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

### Style Composition

```swift
// Use with modifier
Button("Hello") { }
    .buttonStyle(ProminentButtonStyle())

// Or apply at the view hierarchy level
Label("Title", systemImage: "star")
    .labelStyle(IconLabelStyle())
```

---

## Layer Escalation Decision Tree

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

## Anti-Patterns

### Over-Engineering

```swift
// BAD: Creating a Style when a simple modifier would suffice
struct SimpleTextStyle: TextStyle { ... }  // Overkill

// GOOD: Just use .fontWeight()
Text("Hello").fontWeight(.prominent)
```

### Environment Abuse

```swift
// BAD: Using Environment for dependency injection
struct NetworkClient: EnvironmentKey {
    static let defaultValue: NetworkClientProtocol = RealClient()
}

// GOOD: Use protocols for DI
protocol NetworkClientProtocol { ... }
```

### Modifier Explosion

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

## Further Reading

- Apple's [Styling Views](https://developer.apple.com/documentation/swiftui/view-styling) documentation
- [SwiftUI Style Protocols](https://developer.apple.com/documentation/swiftui/buttonstyle) guide
- [EnvironmentValues](https://developer.apple.com/documentation/swiftui/environmentvalues) pattern