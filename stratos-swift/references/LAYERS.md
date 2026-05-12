# Swift Library Layer Reference

Detailed implementation guidance for each of the four Stratos layers in Swift library contexts.

---

## Layer 1: Troposphere — Sensible Defaults

### Implementation Guidelines

Troposphere-level APIs should work immediately with zero configuration:

```swift
// Good: Sensible defaults
struct HTTPClient {
    let baseURL: URL
    let timeout: TimeInterval = 30  // Default

    init(baseURL: URL) {
        self.baseURL = baseURL
    }
}

// Usage: Just needs the base URL
let client = HTTPClient(baseURL: URL(string: "https://api.example.com")!)
```

### What Belongs Here

- Required data (baseURL, endpoints)
- Sensible defaults (timeout: 30, retries: 3)
- Single initializer with max 3-4 parameters

### What Doesn't Belong

- Optional configuration
- Platform-specific behavior
- Debug/logging options

---

## Layer 2: Stratosphere — Configuration

### Implementation Patterns

```swift
// Pattern 1: Configuration struct
struct HTTPClientConfig {
    var timeout: TimeInterval = 30
    var retries: Int = 3
    var headers: [String: String] = [:]
}

struct HTTPClient {
    let config: HTTPClientConfig

    init(baseURL: URL, config: HTTPClientConfig = .init()) {
        self.baseURL = baseURL
        self.config = config
    }
}

// Usage:
let client = HTTPClient(
    baseURL: url,
    config: HTTPClientConfig(timeout: 60, retries: 5)
)

// Pattern 2: Builder
let client = HTTPClient(baseURL: url)
    .timeout(60)
    .retries(5)
    .header("Authorization", "Bearer token")
```

### Guidelines

- Config structs should be `Equatable` for testing
- Builders should return `Self` for chaining
- Consider default values at every level

---

## Layer 3: Mesosphere — Dependency Injection

### When to Use DI

Use for:
- **External dependencies**: Network clients, storage
- **Platform abstractions**: File system, dates
- **Test mocks**: Replace real implementations in tests

Don't use for:
- **Singleton-like concerns**: Use actors
- **Configuration**: Use config structs (Layer 2)
- **Ephemeral state**: Use local variables

### Implementation Pattern

```swift
// Protocol for dependency
protocol NetworkClient {
    func fetch<T: Decodable>(_ type: T.Type, from: URL) async throws -> T
}

// Protocol for configuration
protocol HTTPClientProtocol {
    func get<T>(_ type: T.Type, path: String) async throws -> T
}

// Default implementation
struct DefaultHTTPClient: HTTPClientProtocol {
    let baseURL: URL
    let session: URLSession

    func get<T>(_ type: T.Type, path: String) async throws -> T {
        // Implementation
    }
}

// Usage in consumer
struct UserService {
    let client: HTTPClientProtocol  // Inject via init

    func fetchUsers() async throws -> [User] {
        try await client.get([User].self, "/users")
    }
}

// Test injection
final class MockHTTPClient: HTTPClientProtocol {
    var result: Result<[User], Error> = .success([])

    func get<T>(_ type: T.Type, path: String) async throws -> T {
        try result.get() as! T
    }
}
```

---

## Layer 4: Thermosphere — Deep Customization

### When to Use

Thermosphere is for power users who need full control. Most library users should stop at Layer 2-3.

Use for:
- Custom serialization strategies
- Plugin architectures
- Advanced middleware/chaining

### Example: Middleware Chain

```swift
protocol HTTPMiddleware {
    func intercept(_ request: inout URLRequest) async throws
}

struct AuthMiddleware: HTTPMiddleware {
    let token: String

    func intercept(_ request: inout URLRequest) async throws {
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
}

struct LoggingMiddleware: HTTPMiddleware {
    func intercept(_ request: inout URLRequest) async throws {
        print("Request: \(request.url!)")
    }
}

// Usage:
var config = HTTPClientConfig()
config.middlewares = [AuthMiddleware(token: "..."), LoggingMiddleware()]
let client = HTTPClient(baseURL: url, config: config)
```

### Example: Custom Serialization

```swift
protocol JSONDecoderProtocol {
    func decode<T: Decodable>(_ type: T.Type, from: Data) throws -> T
}

struct CustomDecoder: JSONDecoderProtocol {
    let keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy
    let dateDecodingStrategy: JSONDecoder.DateDecodingStrategy

    func decode<T: Decodable>(_ type: T.Type, from: Data) throws -> T {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = keyDecodingStrategy
        decoder.dateDecodingStrategy = dateDecodingStrategy
        return try decoder.decode(type, from: from)
    }
}
```

---

## Layer Escalation Decision Tree

```
Does the library have a common use case?
├─ NO → Start at Layer 1
└─ YES → Does the common case need customization?
          ├─ NO → Layer 1 sufficient
          └─ YES → Is the customization static (set once)?
                    ├─ NO → Use Layer 2 (config/builder)
                    └─ YES → Does the customization vary by context?
                              ├─ NO → Layer 2
                              └─ YES → Use Layer 3 (DI)
```

**Only escalate to Layer 4 when:**
- Layer 2-3 patterns have been proven insufficient
- The use case genuinely requires a plugin/extension architecture
- You're building a framework meant for third-party extension

---

## Anti-Patterns

### Configuration Explosion

```swift
// BAD: Too many parameters
init(
    baseURL: URL,
    timeout: TimeInterval,
    retries: Int,
    cacheEnabled: Bool,
    cacheSize: Int,
    logger: Logger,
    middleware: [Middleware],
    encoder: Encoder,
    decoder: Decoder
)

// GOOD: Layered configuration
init(baseURL: URL)  // Required
.timeout(30)        // Layer 2
.cache(enabled: true, size: 100)  // Grouped
```

### Leaky Abstractions

```swift
// BAD: Exposing internal types
public struct Client {
    internal let session: URLSession
    public let queue: DispatchQueue  // Leaky abstraction
}

// GOOD: Hide implementation details
public protocol ClientProtocol {
    func fetch<T>(_: T.Type) async throws -> T
}
```

### Global State

```swift
// BAD: Global mutable state
static var globalClient: Client?

// GOOD: Pass dependencies
struct Service {
    let client: ClientProtocol
}
```

---

## Swift 6 Migration Checklist

- [ ] Enable strict concurrency checking
- [ ] Add `Sendable` to public structs/enums
- [ ] Use `@MainActor` for UI-bound types
- [ ] Convert completion handlers to async
- [ ] Use actors for shared mutable state
- [ ] Remove `@escaping` where async allows
- [ ] Test with `-sanitize=thread`

---

## Further Reading

- [Swift.org Concurrency](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)
- [Swift Evolution SE-0303](https://github.com/apple/swift-evolution/blob/main/proposals/0303-actor-isolation.md) — Actor isolation
- [API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)