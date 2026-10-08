# Swift Library Layer Reference

Detailed implementation guidance for each of the four Stratos layers in Swift library and SDK contexts.

---

## Layer 1: Troposphere — Sensible Defaults

### Implementation Guidelines

Troposphere-level APIs work out of the box with zero configuration ceremony:

```swift
public struct HTTPClient: Sendable {
    public let baseURL: URL
    public var timeout: Duration = .seconds(30)
    public var maxRetries: Int = 3

    public init(baseURL: URL) {
        self.baseURL = baseURL
    }
}

// Usage: Only requires the essential identity (baseURL)
let client = HTTPClient(baseURL: apiURL)
```

### What Belongs Here

- Required identity/data (`baseURL`, target resource)
- Sensible defaults (`timeout = .seconds(30)`, `maxRetries = 3`)
- Single primary initializer with at most 3–4 parameters

### What Doesn't Belong

- Rare edge-case flags
- Custom transport/session overrides (→ Layer 3)
- Interceptor pipelines (→ Layer 4)

---

## Layer 2: Stratosphere — Configuration & Fluent Builders

### Implementation Patterns

Provide value-semantic fluent methods (or a cohesive `Configuration` struct with defaults) for per-instance tuning:

```swift
// Pattern A: Fluent copy-on-modify builders
extension HTTPClient {
    public func timeout(_ duration: Duration) -> Self {
        var copy = self
        copy.timeout = duration
        return copy
    }

    public func retries(_ count: Int) -> Self {
        var copy = self
        copy.maxRetries = count
        return copy
    }
}

// Usage:
let client = HTTPClient(baseURL: apiURL)
    .timeout(.seconds(60))
    .retries(5)

// Pattern B: Cohesive configuration struct with defaults
public struct HTTPClientConfiguration: Sendable, Equatable {
    public var timeout: Duration = .seconds(30)
    public var maxRetries: Int = 3
    public var defaultHeaders: [String: String] = [:]

    public init(
        timeout: Duration = .seconds(30),
        maxRetries: Int = 3,
        defaultHeaders: [String: String] = [:]
    ) {
        self.timeout = timeout
        self.maxRetries = maxRetries
        self.defaultHeaders = defaultHeaders
    }
}
```

### Guidelines

- Config structs must conform to `Sendable` and `Equatable`.
- Fluent builder methods return `Self` so configuration stays immutable (`let client = ...`) at the call site.

---

## Layer 3: Mesosphere — Dependency Injection & Context

### When to Use DI & `@TaskLocal`

Use Layer 3 for:
- **External transports**: Network sessions, persistence engines, keychain stores
- **Deterministic testing**: Injecting clocks (`any Clock<Duration>`), UUID generators, or mock transports
- **Implicit request context**: Propagating trace IDs or logger metadata via `@TaskLocal`

### Implementation Pattern

Always mark dependency protocols as `: Sendable` so services can be safely shared across actors and `@MainActor` views:

```swift
public protocol HTTPTransport: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

public struct URLSessionTransport: HTTPTransport {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        return (data, httpResponse)
    }
}

public struct UserService: Sendable {
    private let transport: any HTTPTransport

    // Default argument keeps Layer 1 zero-config while unlocking Layer 3 testability!
    public init(transport: any HTTPTransport = URLSessionTransport()) {
        self.transport = transport
    }
}

// Thread-safe test double using an actor or immutable stub:
public struct StubHTTPTransport: HTTPTransport {
    public var responseData: Data
    public var statusCode: Int = 200

    public func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        return (responseData, response)
    }
}
```

---

## Layer 4: Thermosphere — Deep Customization

### When to Use

Thermosphere is for power users who need custom cross-cutting pipelines or serialization engines. Most library consumers should stop at Layers 1–3.

### Example: Async Middleware Chain

```swift
public protocol HTTPMiddleware: Sendable {
    func intercept(
        _ request: URLRequest,
        next: @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)
    ) async throws -> (Data, HTTPURLResponse)
}

public struct BearerAuthMiddleware: HTTPMiddleware {
    private let tokenProvider: @Sendable () async throws -> String

    public init(tokenProvider: @escaping @Sendable () async throws -> String) {
        self.tokenProvider = tokenProvider
    }

    public func intercept(
        _ request: URLRequest,
        next: @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)
    ) async throws -> (Data, HTTPURLResponse) {
        var signedRequest = request
        let token = try await tokenProvider()
        signedRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return try await next(signedRequest)
    }
}
```

### Example: Non-Copyable Resource Handles (`~Copyable`)

For low-level resources that require strict single-ownership (file descriptors, database transactions, cryptographic contexts), use `~Copyable` with `consuming` methods to prevent double-close bugs at compile time:

```swift
public struct TransactionHandle: ~Copyable, Sendable {
    private var isCommitted = false

    public consuming func commit() throws {
        // Consumes `self` — caller cannot use or rollback the handle after committing!
    }

    deinit {
        if !isCommitted {
            // Automatically roll back if dropped without calling commit()
        }
    }
}
```

---

## Layer Escalation Decision Tree

```
Does the library have a clear 90% use case?
├─ NO  → Refine Layer 1 until the primary operation takes 1–2 lines
└─ YES → Do callers need to tune individual calls or instances?
          ├─ NO  → Stop at Layer 1 (Troposphere)
          └─ YES → Is it a value/policy tweak (timeout, retry, format)?
                    ├─ YES → Expose fluent modifiers / config in Layer 2 (Stratosphere)
                    └─ NO  → Does it swap an external boundary (transport, clock, storage)?
                              ├─ YES → Inject a `Sendable` protocol with a default in Layer 3 (Mesosphere)
                              └─ NO  → Expose a Middleware / Strategy protocol in Layer 4 (Thermosphere)
```

---

## Anti-Patterns

### Configuration Explosion in `init`

```swift
// BAD: Forces every caller to confront 8 parameters upfront
public init(
    baseURL: URL,
    timeout: Duration,
    retries: Int,
    cacheEnabled: Bool,
    cacheSize: Int,
    logger: Logger?,
    middlewares: [any HTTPMiddleware],
    decoder: JSONDecoder
)

// GOOD: Progressive Disclosure
let client = HTTPClient(baseURL: apiURL)              // Layer 1
    .timeout(.seconds(30))                            // Layer 2
    .cache(.memory(limitBytes: 50_000_000))           // Layer 2 (semantic enum, no boolean trap)
```

### Leaky Abstractions

```swift
// BAD: Exposing internal concurrency primitives on public types
public struct Client {
    public let queue: DispatchQueue
}

// GOOD: Encapsulate synchronization inside an actor or Sendable type
public actor Client {
    public func performWork() async throws -> ResultData { ... }
}
```

---

## Swift 6 Migration Checklist

- [ ] Enable Swift 6 language mode or `-strict-concurrency=complete`
- [ ] Add `Sendable` to public structs, enums, and protocols
- [ ] Mark view-bound observable models with `@MainActor`
- [ ] Audit `actor` methods for state changes across `await` suspension points
- [ ] Replace `NSLock` + `@unchecked Sendable` with `Mutex` (from `Synchronization`) or `actor`
- [ ] Use Typed Throws (`throws(DomainError)`) for closed, exhaustive error domains
- [ ] Test concurrent workloads with Thread Sanitizer (`-sanitize=thread`)

---

## Further Reading

- [Swift Concurrency Documentation](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)
- [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)
- [SE-0413: Typed Throws](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0413-typed-throws.md)
- [SE-0433: Synchronous Mutual Exclusion Lock (`Mutex`)](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0433-mutex.md)