#!/usr/bin/env swift

import Foundation

struct CodeSnippet: Sendable {
    let file: String
    let startLine: Int
    let endLine: Int
    let code: String
}

struct SnippetVerificationResult: Sendable {
    let index: Int
    let snippet: CodeSnippet
    let mode: String
    let passed: Bool
    let diagnostic: String
}

func discoverTargetFiles(at basePath: String) -> [(fileURL: URL, label: String)] {
    let fm = FileManager.default
    let baseURL = URL(fileURLWithPath: basePath)
    var isDir: ObjCBool = false

    guard fm.fileExists(atPath: baseURL.path, isDirectory: &isDir) else {
        return []
    }

    // Case 1: Single file passed directly
    if !isDir.boolValue {
        return [(baseURL, basePath)]
    }

    var results: [(fileURL: URL, label: String)] = []

    func collectSkillFiles(in skillDir: URL, prefix: String) {
        let skillMD = skillDir.appendingPathComponent("SKILL.md")
        if fm.fileExists(atPath: skillMD.path) {
            results.append((skillMD, "\(prefix)/SKILL.md"))
        }
        let refDir = skillDir.appendingPathComponent("references")
        if let refs = try? fm.contentsOfDirectory(at: refDir, includingPropertiesForKeys: nil) {
            for ref in refs.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
                if !ref.lastPathComponent.hasPrefix(".") && ref.pathExtension.lowercased() == "md" {
                    results.append((ref, "\(prefix)/references/\(ref.lastPathComponent)"))
                }
            }
        }
    }

    // Case 2: Single skill directory passed directly
    let directSkillMD = baseURL.appendingPathComponent("SKILL.md")
    if fm.fileExists(atPath: directSkillMD.path) {
        let skillName = baseURL.standardizedFileURL.lastPathComponent
        collectSkillFiles(in: baseURL, prefix: skillName)
        return results
    }

    // Case 3: Repository root directory
    if let topItems = try? fm.contentsOfDirectory(at: baseURL, includingPropertiesForKeys: [.isDirectoryKey]) {
        for item in topItems.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            if item.lastPathComponent.hasPrefix(".") { continue }
            let itemIsDir = (try? item.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
            if itemIsDir && fm.fileExists(atPath: item.appendingPathComponent("SKILL.md").path) {
                collectSkillFiles(in: item, prefix: item.lastPathComponent)
            }
        }
    }

    let evalTestsDir = baseURL.appendingPathComponent("evals/tests")
    if let evalFiles = try? fm.contentsOfDirectory(at: evalTestsDir, includingPropertiesForKeys: nil) {
        for evalFile in evalFiles.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            let ext = evalFile.pathExtension.lowercased()
            if !evalFile.lastPathComponent.hasPrefix(".") && (ext == "yaml" || ext == "yml") {
                results.append((evalFile, "evals/tests/\(evalFile.lastPathComponent)"))
            }
        }
    }

    return results
}

func extractSnippets(from fileURL: URL, label: String) -> [CodeSnippet] {
    guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else {
        return []
    }

    let lines = content.components(separatedBy: "\n")
    var snippets: [CodeSnippet] = []
    var inBlock = false
    var startLine = 0
    var indentPrefix = ""
    var currentLines: [String] = []

    for (idx, line) in lines.enumerated() {
        let lineNumber = idx + 1
        let trimmed = line.drop(while: { $0 == " " || $0 == "\t" })

        if !inBlock && trimmed.hasPrefix("```swift") {
            inBlock = true
            startLine = lineNumber
            let prefixCount = line.count - trimmed.count
            indentPrefix = String(line.prefix(prefixCount))
            currentLines = []
        } else if inBlock && trimmed.hasPrefix("```") {
            inBlock = false
            snippets.append(
                CodeSnippet(
                    file: label,
                    startLine: startLine,
                    endLine: lineNumber,
                    code: currentLines.joined(separator: "\n")
                )
            )
        } else if inBlock {
            if !indentPrefix.isEmpty && line.hasPrefix(indentPrefix) {
                currentLines.append(String(line.dropFirst(indentPrefix.count)))
            } else {
                currentLines.append(line)
            }
        }
    }

    return snippets
}

let baseContext = """
import SwiftUI
import Foundation
import Observation
import Synchronization

public let apiURL = URL(string: "https://api.example.com")!
public let endpoint = URL(string: "https://api.example.com/v1")!
public let localFileURL = URL(fileURLWithPath: "/tmp/avatar.jpg")
public let includeAuth = true
public let token = "secret-token"
public let secret = "hmac-secret"
public let isHighlighted = true
@Sendable public func submit() {}
@Sendable public func play() {}
@Sendable public func fetch(_ url: URL) async throws -> Data { Data() }

public struct Claims: Sendable { public init(rawToken: String = "") {} }
public struct User: Identifiable, Codable, Sendable {
    public let id: String
}
public protocol NetworkTransport: Sendable {
    func fetchUser(id: User.ID) async throws -> User
}
public enum HTTPMethod: Sendable {
    case get, post, put, delete
}
public enum RetryPolicy: Sendable {
    case exponentialBackoff(maxAttempts: Int)
}
public enum CacheConfiguration: Sendable {
    case memory(limitBytes: Int)
}
public struct HmacSigningMiddleware: Sendable {
    public init(key: String) {}
}
public enum ThemeChoice: Sendable {
    case dark, light
}
public struct MyApp: View {
    public init() {}
    public var body: some View { EmptyView() }
    public func theme(_ choice: ThemeChoice) -> some View { self }
}
public struct HoldToConfirmButtonStyle: ButtonStyle {
    public init(duration: Duration) {}
    public func makeBody(configuration: Configuration) -> some View { configuration.label }
}
public enum ComparisonPeriod: Sendable { case previousQuarter }
public enum ExportFormat: Sendable { case pdf }
public struct AnalyticsReport: Sendable {
    public init(_ title: String) {}
    public func comparisonPeriod(_ period: ComparisonPeriod) -> Self { self }
    public func export(as format: ExportFormat) async throws -> Data { Data() }
}
public enum AvatarSize: Sendable { case small, medium, large }
public enum Presence: Sendable { case online, offline }
public struct AvatarTheme: Sendable { public init() {} }
extension EnvironmentValues {
    @Entry public var avatarTheme: AvatarTheme = AvatarTheme()
}
public enum TextWeight: Sendable { case regular, prominent, subtle }
public enum Elevation: Sendable { case flat, raised, floating }
public enum DismissBehavior: Sendable { case swipe, button }
public protocol AnalyticsTracking: Sendable {}
public struct DefaultTracker: AnalyticsTracking {
    public static let shared = DefaultTracker()
}
public struct FileUploader {
    public init(
        fileURL: URL,
        destinationBucket: String,
        chunkSize: Int,
        compressBeforeUpload: Bool,
        compressionQuality: Double,
        encryptionMode: String,
        onProgress: @escaping (Double) -> Void,
        customTransport: Any?
    ) {}
    public func start() async throws {}
}
public enum UploadDestination: Sendable { case userAvatars }
public enum UploadCompression: Sendable { case jpeg(quality: Double) }
public enum UploadEncryption: Sendable { case aes256 }
public protocol UploadTransport: Sendable {}
public struct MockChunkedTransport: UploadTransport { public init() {} }
public protocol UploadStrategy: Sendable {}
public struct AdaptiveMultistreamStrategy: UploadStrategy {
    public init(maxConcurrentStreams: Int) {}
}
public struct FileUpload {
    public init(from url: URL, to destination: UploadDestination) {}
    public func compression(_ c: UploadCompression) -> Self { self }
    public func encryption(_ e: UploadEncryption) -> Self { self }
    public func onProgress(_ handler: @escaping (Progress) -> Void) -> Self { self }
    public func uploadStrategy(_ s: any UploadStrategy) -> Self { self }
    public func send() async throws {}
}
public struct FileUploadService {
    public init(transport: any UploadTransport) {}
    public func upload(_ url: URL, to destination: UploadDestination) async throws {}
}
public struct RequestConfig: Sendable {
    public enum Feature: Sendable { case beta }
    public init() {}
    public mutating func enableFeature(_ name: String) {}
    public mutating func setTimeout(_ seconds: Int) {}
    public func feature(_ f: Feature) -> Self { self }
    public func timeout(_ d: Duration) -> Self { self }
}
public struct Status: Sendable {
    public let displayName: String
    public let color: Color
    public static let active = Status(displayName: "Active", color: .green)
}
public struct Theme: Equatable, Sendable {
    public var primaryColor: Color = .primary
    public var surfaceColor: Color = .secondary.opacity(0.12)
    public var cornerRadius: CGFloat = 12
    public static let light = Theme()
}
public enum TextRole: Sendable { case heroTitle }
public enum CustomTextStyle: Sendable { case captionProminent }
public enum StatusTone: Sendable { case warning }
extension View {
    public func textRole(_ role: TextRole) -> some View { self }
    public func textStyle(_ style: CustomTextStyle) -> some View { self }
    public func statusTone(_ tone: StatusTone) -> some View { self }
    public func setBold(_ isBold: Bool) -> some View { self }
    public func shadowRadius(_ radius: CGFloat) -> some View { self }
    public func backgroundColor(_ color: Color) -> some View { self }
    public func fontSize(_ size: CGFloat) -> some View { self }
    public func letterSpacing(_ spacing: CGFloat) -> some View { self }
}
public struct DataSource: Sendable {}
public struct Logger: Sendable {}
public struct ResultData: Sendable {}
public struct NetworkConfig: Sendable {
    public init() {}
    public mutating func setMode(_ mode: String) {}
    public mutating func enableLogging(_ enabled: Bool) {}
}
"""

func buildContext(for code: String) -> String {
    var chunks: [String] = [baseContext]

    if !code.contains("struct HTTPClient:") {
        chunks.append("""
        public struct HTTPClient: Sendable {
            public let baseURL: URL
            public var timeout: Duration = .seconds(30)
            public var maxRetries: Int = 3
            public init(baseURL: URL, middlewares: [any Sendable] = []) { self.baseURL = baseURL }
            public func retryPolicy(_ policy: RetryPolicy) -> Self { self }
            public func cache(_ config: CacheConfiguration) -> Self { self }
            public func get<T: Decodable>(_ path: String) async throws -> T { fatalError() }
        }
        public let authenticatedClient = HTTPClient(baseURL: apiURL)
        """)
        if !code.contains("func timeout(") {
            chunks.append("""
            extension HTTPClient {
                public func timeout(_ duration: Duration) -> Self { self }
                public func retries(_ count: Int) -> Self { self }
            }
            """)
        }
    }
    if !code.contains("struct UserService") {
        chunks.append("""
        public struct UserService: Sendable {
            public init(client: HTTPClient) {}
        }
        """)
    }
    if !code.contains("struct Badge<") && !code.contains("struct Badge:") {
        chunks.append("""
        public enum BadgeProminence: Sendable { case standard, prominent }
        public struct Badge<Content: View>: View {
            private let content: Content
            public init(@ViewBuilder content: () -> Content) { self.content = content() }
            public var body: some View { content }
        }
        extension Badge where Content == Text {
            public init(_ titleKey: LocalizedStringKey) { self.init { Text(titleKey) } }
        }
        extension EnvironmentValues {
            @Entry public var badgeProminence: BadgeProminence = .standard
        }
        """)
        if !code.contains("func badgeProminence(") {
            chunks.append("""
            extension View {
                public func badgeProminence(_ prominence: BadgeProminence) -> some View {
                    environment(\\.badgeProminence, prominence)
                }
            }
            """)
        }
    }
    if !code.contains("enum CardElevation") {
        chunks.append("""
        public enum CardElevation: Sendable { case flat, raised, floating }
        extension View {
            public func cardElevation(_ elevation: CardElevation) -> some View { self }
        }
        """)
    }
    if !code.contains("struct CardTheme") {
        chunks.append("""
        public struct CardTheme: Equatable, Sendable {
            public static let standard = CardTheme()
            public static let highContrast = CardTheme()
        }
        extension View {
            public func cardTheme(_ theme: CardTheme) -> some View { self }
        }
        """)
    }
    if !code.contains("@Entry var theme:") {
        chunks.append("""
        extension EnvironmentValues {
            @Entry public var theme: Theme = .light
        }
        """)
    }
    if !code.contains("protocol CardStyle") {
        chunks.append("""
        struct CardStyleConfiguration {
            struct Content: View { let body: AnyView }
            let content: Content
        }
        protocol CardStyle: Sendable {
            associatedtype Body: View
            @MainActor @ViewBuilder func makeBody(configuration: CardStyleConfiguration) -> Body
        }
        struct ElevatedCardStyle: CardStyle {
            func makeBody(configuration: CardStyleConfiguration) -> some View { configuration.content }
        }
        extension CardStyle where Self == ElevatedCardStyle {
            static var elevated: ElevatedCardStyle { ElevatedCardStyle() }
        }
        extension EnvironmentValues {
            @Entry var cardStyle: any CardStyle = ElevatedCardStyle()
        }
        extension View {
            func cardStyle(_ style: some CardStyle) -> some View {
                environment(\\.cardStyle, style)
            }
        }
        """)
    }
    if !code.contains("struct BorderedCardStyle") {
        chunks.append("""
        struct BorderedCardStyle: CardStyle {
            init() {}
            func makeBody(configuration: CardStyleConfiguration) -> some View { configuration.content }
        }
        """)
    }
    if !code.contains("struct Card<") {
        chunks.append("""
        struct Card<Content: View>: View {
            init(@ViewBuilder content: () -> Content) {}
            var body: some View { EmptyView() }
        }
        """)
    }
    if !code.contains("func `if`") {
        chunks.append("""
        extension View {
            @ViewBuilder
            public func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
                if condition { transform(self) } else { self }
            }
        }
        """)
    }
    if !code.contains("protocol HTTPMiddleware") {
        chunks.append("""
        public protocol HTTPMiddleware: Sendable {}
        """)
    }
    return chunks.joined(separator: "\n\n")
}

func runSwiftc(contextCode: String, mainCode: String, tempDir: URL, moduleCachePath: String) -> (Bool, String) {
    let ctxFile = tempDir.appendingPathComponent("context.swift")
    let mainFile = tempDir.appendingPathComponent("main.swift")

    let fullMain = "import SwiftUI\nimport Foundation\nimport Observation\nimport Synchronization\n\n" + mainCode
    try? contextCode.write(to: ctxFile, atomically: true, encoding: .utf8)
    try? fullMain.write(to: mainFile, atomically: true, encoding: .utf8)

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
    process.arguments = [
        "swiftc",
        "-disable-sandbox",
        "-typecheck",
        "-swift-version", "6",
        "-module-cache-path", moduleCachePath,
        ctxFile.path,
        mainFile.path
    ]

    let errPipe = Pipe()
    process.standardError = errPipe
    process.standardOutput = Pipe()

    do {
        try process.run()
        process.waitUntilExit()
    } catch {
        return (false, "Failed to invoke swiftc: \(error)")
    }

    let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
    let stderr = String(data: errData, encoding: .utf8) ?? ""

    if process.terminationStatus == 0 {
        return (true, "")
    }
    let firstError = stderr.components(separatedBy: "\n").first(where: { $0.contains("error:") }) ?? stderr
    return (false, firstError)
}

/// Normalizes documentation shorthand (such as `{ ... }` elision, signature-only blocks, or `BAD`/`GOOD` comparisons)
/// when a snippet is not intended to be a single verbatim compilation unit.
func normalizeDocSnippet(_ rawCode: String) -> [String] {
    let splitMarkers = ["// GOOD:", "// REPLACE WITH:", "// AFTER:"]
    for marker in splitMarkers {
        if let range = rawCode.range(of: marker) {
            let firstHalf = String(rawCode[..<range.lowerBound])
            let secondHalf = String(rawCode[range.lowerBound...])
            return normalizeSingleSection(firstHalf) + normalizeSingleSection(secondHalf)
        }
    }
    return normalizeSingleSection(rawCode)
}

func normalizeSingleSection(_ section: String) -> [String] {
    var code = section

    // 1. Expand `{ ... }` elision markers
    if code.contains("-> ResultData { ... }") {
        code = code.replacingOccurrences(of: "{ ... }", with: "{ ResultData() }")
    } else if code.contains("{ ... }") {
        code = code.replacingOccurrences(of: "{ ... }", with: "{}")
    }

    // 2. Add `var body: some View` if a View struct omits it for brevity
    if code.contains(": View {") && !code.contains("var body:") {
        code = code.replacingOccurrences(
            of: ": View {",
            with: ": View {\n    var body: some View { EmptyView() }"
        )
    }

    // 3. Complete bodyless `-> Self` method signatures inside a struct
    if code.contains("struct ") && code.contains("-> Self") && !code.contains("return ") && !code.contains("{ self }") {
        let lines = code.components(separatedBy: "\n").map { line -> String in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("func ") && trimmed.contains("-> Self") && !trimmed.contains("{") {
                if let commentRange = line.range(of: "//") {
                    let beforeComment = String(line[..<commentRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                    let comment = String(line[commentRange.lowerBound...])
                    return "    \(beforeComment) { self } \(comment)"
                }
                return line + " { self }"
            }
            return line
        }
        code = lines.joined(separator: "\n")
    }

    let nonCommentLines = code.components(separatedBy: "\n")
        .map { $0.trimmingCharacters(in: .whitespaces) }
        .filter { !$0.isEmpty && !$0.hasPrefix("//") }

    // 4. Bare modifier list (every non-comment line begins with `.`)
    if !nonCommentLines.isEmpty && nonCommentLines.allSatisfy({ $0.hasPrefix(".") }) {
        return ["let _ = Text(\"Preview\")\n" + code]
    }

    // 5. Bare `public init` / `init` outside a type definition
    let hasTypeContainer = code.contains("struct ") || code.contains("class ") || code.contains("actor ") || code.contains("protocol ") || code.contains("extension ")
    if !hasTypeContainer && (code.contains("public init(") || code.contains("init(")) {
        let lines = code.components(separatedBy: "\n")
        var memberLines: [String] = []
        var callLines: [String] = []
        var inCallSite = false
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("let ") {
                inCallSite = true
            }
            if inCallSite {
                callLines.append(line)
            } else {
                let codePart: String
                let commentPart: String
                if let commentRange = line.range(of: "//") {
                    codePart = String(line[..<commentRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                    commentPart = " " + String(line[commentRange.lowerBound...])
                } else {
                    codePart = trimmed
                    commentPart = ""
                }
                if codePart.hasSuffix("-> Self") {
                    memberLines.append("    \(codePart) { self }\(commentPart)")
                } else if codePart.hasSuffix(")") {
                    memberLines.append("    \(codePart) {}\(commentPart)")
                } else {
                    memberLines.append(line)
                }
            }
        }
        let members = memberLines.joined(separator: "\n")
        let wrapped = "public struct _DocSignatureContainer {\n\(members)\n}\n" + callLines.joined(separator: "\n")
        return [wrapped]
    }

    // 6. Bare method signatures returning `Self` outside a type
    if !hasTypeContainer && code.contains("-> Self") && !code.contains("view.") {
        return ["protocol _DocSignatureProtocol {\n\(code)\n}"]
    }

    // 7. Signature declaration followed immediately by `service.` or `view.` call
    if !hasTypeContainer && (code.contains("service.") || code.contains("view.")) {
        let receiverName = code.contains("service.") ? "service" : "view"
        let lines = code.components(separatedBy: "\n")
        var enumLines: [String] = []
        var funcLines: [String] = []
        var callLines: [String] = []
        for line in lines {
            let t = line.trimmingCharacters(in: .whitespaces)
            if t.hasPrefix("enum ") {
                enumLines.append(line)
            } else if t.hasPrefix("func ") {
                if t.contains("-> Self") {
                    funcLines.append(line + " { self }")
                } else {
                    funcLines.append(line + " {}")
                }
            } else if !t.isEmpty && !t.hasPrefix("//") {
                callLines.append(line)
            }
        }
        let combined = """
        \(enumLines.joined(separator: "\n"))
        struct _ReceiverStub {
            \(funcLines.joined(separator: "\n    "))
        }
        let \(receiverName) = _ReceiverStub()
        \(callLines.joined(separator: "\n"))
        """
        return [combined]
    }

    return [code]
}

func verifySnippet(_ snippet: CodeSnippet, index: Int, rootTempDir: URL, moduleCachePath: String) -> SnippetVerificationResult {
    let workerDir = rootTempDir.appendingPathComponent("snippet_\(index)")
    try? FileManager.default.createDirectory(at: workerDir, withIntermediateDirectories: true)

    var code = snippet.code
    if code.contains("class UserViewModel") {
        code = "let userViewModel = UserViewModel()\n" + code
    }
    let contextCode = buildContext(for: code)

    // Step 1: Try compiling the snippet 100% verbatim
    let (verbatimPassed, verbatimError) = runSwiftc(
        contextCode: contextCode,
        mainCode: code,
        tempDir: workerDir,
        moduleCachePath: moduleCachePath
    )
    if verbatimPassed {
        return SnippetVerificationResult(
            index: index,
            snippet: snippet,
            mode: "verbatim",
            passed: true,
            diagnostic: ""
        )
    }

    // Step 2: Try normalizing known documentation shorthand (`{ ... }`, signature-only blocks, BAD/GOOD splits)
    let normalizedSections = normalizeDocSnippet(code)
    var allNormalizedPassed = true
    var firstFailureDiagnostic = verbatimError

    for (subIdx, sectionCode) in normalizedSections.enumerated() {
        let subDir = workerDir.appendingPathComponent("sub_\(subIdx)")
        try? FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)
        let subContext = buildContext(for: sectionCode)
        let (subPassed, subError) = runSwiftc(
            contextCode: subContext,
            mainCode: sectionCode,
            tempDir: subDir,
            moduleCachePath: moduleCachePath
        )
        if !subPassed {
            allNormalizedPassed = false
            firstFailureDiagnostic = subError
            break
        }
    }

    return SnippetVerificationResult(
        index: index,
        snippet: snippet,
        mode: allNormalizedPassed ? "normalized-doc-snippet" : "failed",
        passed: allNormalizedPassed,
        diagnostic: allNormalizedPassed ? "" : firstFailureDiagnostic
    )
}

func printUsage() {
    print("""
    Usage: swift scripts/verify-snippets.swift [options] [path]

    Options:
      -h, --help   Show this help message
    """)
}

func main() {
    let rawArgs = Array(CommandLine.arguments.dropFirst())
    let knownFlags: Set<String> = ["--help", "-h"]
    let flags = rawArgs.filter { $0.hasPrefix("-") }
    let unknownFlags = flags.filter { !knownFlags.contains($0) }

    if !unknownFlags.isEmpty {
        print("✗ Unknown option(s): \(unknownFlags.joined(separator: ", "))\n")
        printUsage()
        exit(1)
    }

    if flags.contains("--help") || flags.contains("-h") {
        printUsage()
        exit(0)
    }

    let positionalArgs = rawArgs.filter { !$0.hasPrefix("-") }
    let basePath = positionalArgs.first ?? "."
    let baseURL = URL(fileURLWithPath: basePath)

    print("Verifying Swift & SwiftUI code snippets in: \(basePath)\n")

    let discoveredFiles = discoverTargetFiles(at: basePath)
    var allSnippets: [CodeSnippet] = []
    for item in discoveredFiles {
        allSnippets.append(contentsOf: extractSnippets(from: item.fileURL, label: item.label))
    }

    if allSnippets.isEmpty {
        print("✗ No Swift code snippets found in: \(basePath)")
        exit(1)
    }

    let rootTempDir = URL(fileURLWithPath: "/tmp")
        .appendingPathComponent("stratos-snippet-verify-\(ProcessInfo.processInfo.processIdentifier)")
    let moduleCachePath = "/tmp/stratos-clang-module-cache"
    try? FileManager.default.createDirectory(at: rootTempDir, withIntermediateDirectories: true)
    defer {
        try? FileManager.default.removeItem(at: rootTempDir)
    }

    // Also typecheck standalone Swift scripts when validating a directory containing scripts/
    let scriptsDir = baseURL.appendingPathComponent("scripts")
    var scriptErrors: [String] = []
    if let scriptURLs = try? FileManager.default.contentsOfDirectory(at: scriptsDir, includingPropertiesForKeys: nil) {
        for scriptURL in scriptURLs.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            guard !scriptURL.lastPathComponent.hasPrefix("."),
                  scriptURL.pathExtension.lowercased() == "swift" else { continue }
            let relScript = "scripts/\(scriptURL.lastPathComponent)"
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
            proc.arguments = [
                "swiftc",
                "-disable-sandbox",
                "-typecheck",
                "-swift-version", "6",
                "-module-cache-path", moduleCachePath,
                scriptURL.path
            ]
            let errPipe = Pipe()
            proc.standardError = errPipe
            proc.standardOutput = Pipe()
            try? proc.run()
            proc.waitUntilExit()
            if proc.terminationStatus == 0 {
                print("✓ [script] \(relScript) -> PASS (Swift 6)")
            } else {
                let err = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                scriptErrors.append("[\(relScript)] \(err)")
                print("✗ [script] \(relScript) -> FAIL")
            }
        }
    }

    let resultsBox = UnsafeMutableBufferPointer<SnippetVerificationResult?>.allocate(capacity: allSnippets.count)
    resultsBox.initialize(repeating: nil)
    defer { resultsBox.deallocate() }

    DispatchQueue.concurrentPerform(iterations: allSnippets.count) { i in
        let res = verifySnippet(allSnippets[i], index: i + 1, rootTempDir: rootTempDir, moduleCachePath: moduleCachePath)
        resultsBox[i] = res
    }

    let results = resultsBox.compactMap { $0 }
    var failedCount = scriptErrors.count
    var verbatimCount = 0
    var normalizedCount = 0

    for res in results {
        let label = String(format: "[%02d] %@:%d-%d", res.index, res.snippet.file, res.snippet.startLine, res.snippet.endLine)
        if res.passed {
            if res.mode == "verbatim" {
                verbatimCount += 1
            } else {
                normalizedCount += 1
            }
            print("✓ \(label) -> PASS (\(res.mode))")
        } else {
            failedCount += 1
            print("✗ \(label) -> FAIL: \(res.diagnostic)")
        }
    }

    print("\n=== SUMMARY ===")
    print("Total Markdown/YAML snippets checked: \(allSnippets.count) (\(verbatimCount) verbatim, \(normalizedCount) normalized doc snippets)")
    if failedCount == 0 {
        print("✓ All Swift scripts and \(allSnippets.count) code snippets compiled cleanly under Swift 6!")
        exit(0)
    } else {
        print("✗ Verification failed with \(failedCount) error(s)")
        exit(1)
    }
}

main()
