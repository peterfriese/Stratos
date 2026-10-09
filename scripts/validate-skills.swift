#!/usr/bin/env swift

import Foundation

struct ValidationResult {
    var errors: [String] = []
    var warnings: [String] = []
    var passed: [String] = []

    var isSuccess: Bool { errors.isEmpty }
}

struct SkillManifest {
    let path: String
    let name: String
    let description: String
    let author: String?
    let version: String?
    let lineCount: Int
}

func validateSkills(at basePath: String) -> ValidationResult {
    var result = ValidationResult()

    let fileManager = FileManager.default
    let baseURL = URL(fileURLWithPath: basePath)

    var skillDirs: [URL] = []
    let directSkillMD = baseURL.appendingPathComponent("SKILL.md")
    if fileManager.fileExists(atPath: directSkillMD.path) {
        skillDirs.append(baseURL.standardizedFileURL)
    } else {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: baseURL,
            includingPropertiesForKeys: nil
        ) else {
            result.errors.append("Cannot read directory: \(basePath)")
            return result
        }

        for item in contents.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            let isDir = (try? item.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
            if isDir {
                let skillPath = item.appendingPathComponent("SKILL.md")
                if fileManager.fileExists(atPath: skillPath.path) {
                    skillDirs.append(item)
                }
            }
        }
    }

    if skillDirs.isEmpty {
        result.errors.append("No skills found in: \(basePath)")
        return result
    }

    result.passed.append("Found \(skillDirs.count) skill(s)")

    for skillDir in skillDirs {
        let skillName = skillDir.lastPathComponent
        let skillResult = validateSkill(at: skillDir, name: skillName)
        result.errors.append(contentsOf: skillResult.errors)
        result.warnings.append(contentsOf: skillResult.warnings)
        result.passed.append(contentsOf: skillResult.passed)
    }

    return result
}

func validateSkill(at path: URL, name: String) -> ValidationResult {
    var result = ValidationResult()

    let skillPath = path.appendingPathComponent("SKILL.md")

    guard let content = try? String(contentsOf: skillPath, encoding: .utf8) else {
        result.errors.append("[\(name)] Cannot read SKILL.md")
        return result
    }

    let lines = content.components(separatedBy: "\n")
    // Trailing newline produces an empty last element; adjust count to match `wc -l`
    let lineCount = content.hasSuffix("\n") ? lines.count - 1 : lines.count
    result.passed.append("[\(name)] SKILL.md has \(lineCount) lines")

    if lineCount > 500 {
        result.errors.append("[\(name)] SKILL.md has \(lineCount) lines (must be <= 500)")
    } else if lineCount > 350 {
        result.warnings.append("[\(name)] SKILL.md has \(lineCount) lines (recommend <= 350; move details to references/LAYERS.md)")
    }

    guard let frontmatterStart = content.firstIndex(of: Character("-")),
          let frontmatterEnd = content.index(frontmatterStart, offsetBy: 3, limitedBy: content.endIndex),
          content[frontmatterStart..<frontmatterEnd] == "---" else {
        result.errors.append("[\(name)] Missing YAML frontmatter")
        return result
    }

    guard let closingRange = content.range(of: "---", range: content.index(after: frontmatterEnd)..<content.endIndex) else {
        result.errors.append("[\(name)] Invalid YAML frontmatter format")
        return result
    }

    let frontmatter = String(content[content.index(after: frontmatterEnd)..<closingRange.lowerBound])
    let body = String(content[closingRange.upperBound...])

    if let manifest = parseFrontmatter(frontmatter, skillPath: skillPath, skillName: name, lineCount: lineCount, result: &result) {
        validateName(manifest.name, skillName: name, result: &result)
        validateDescription(manifest.description, skillName: name, result: &result)
        validateMetadata(author: manifest.author, version: manifest.version, skillName: name, result: &result)
    }

    validateSections(in: body, skillName: name, result: &result)
    validateRelativeLinks(in: body, baseDir: path, fileLabel: "SKILL.md", skillName: name, result: &result)
    validateReferences(in: path, skillName: name, result: &result)

    return result
}

func parseFrontmatter(
    _ yaml: String,
    skillPath: URL,
    skillName: String,
    lineCount: Int,
    result: inout ValidationResult
) -> SkillManifest? {
    var name: String?
    var description: String?
    var author: String?
    var version: String?
    var inMetadataBlock = false

    let yamlLines = yaml.components(separatedBy: "\n")
    var i = 0

    while i < yamlLines.count {
        let line = yamlLines[i]
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        if trimmed.isEmpty || trimmed.hasPrefix("#") {
            i += 1
            continue
        }

        let isIndented = line.hasPrefix(" ") || line.hasPrefix("\t")
        if !isIndented {
            inMetadataBlock = false
        }

        let keyValuePattern = #"^([\w-]+):\s*(.*)$"#
        if let regex = try? NSRegularExpression(pattern: keyValuePattern),
           let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)),
           let keyRange = Range(match.range(at: 1), in: trimmed) {

            let key = String(trimmed[keyRange]).lowercased()
            var value = ""
            if let valueRange = Range(match.range(at: 2), in: trimmed) {
                value = String(trimmed[valueRange])
            }

            if !isIndented && key == "metadata" {
                inMetadataBlock = true
                i += 1
                continue
            }

            let isMultiline = value.hasPrefix("|") || value.hasPrefix(">")

            if isMultiline {
                var multilineContent: [String] = []
                let indicator = value.hasPrefix("|") ? "|" : ">"
                let firstLine = value.replacingOccurrences(of: indicator, with: "")
                    .trimmingCharacters(in: .whitespaces)
                if !firstLine.isEmpty {
                    multilineContent.append(firstLine)
                }

                i += 1
                while i < yamlLines.count {
                    let nextLine = yamlLines[i]
                    if nextLine.hasPrefix(" ") || nextLine.hasPrefix("\t") {
                        multilineContent.append(nextLine.trimmingCharacters(in: .whitespacesAndNewlines))
                        i += 1
                    } else if nextLine.trimmingCharacters(in: .whitespaces).isEmpty {
                        i += 1
                    } else {
                        break
                    }
                }

                value = multilineContent.joined(separator: " ")
            } else {
                value = value.trimmingCharacters(in: .whitespaces)
                if (value.hasPrefix("\"") && value.hasSuffix("\"")) || (value.hasPrefix("'") && value.hasSuffix("'")) {
                    value = String(value.dropFirst().dropLast())
                }
                i += 1
            }

            value = value.trimmingCharacters(in: .whitespacesAndNewlines)

            if inMetadataBlock && isIndented {
                if key == "author" {
                    author = value
                } else if key == "version" {
                    version = value
                }
            } else if !isIndented {
                if key == "name" {
                    name = value
                } else if key == "description" {
                    description = value
                }
            }
        } else {
            i += 1
        }
    }

    if name == nil {
        result.errors.append("[\(skillName)] Missing required 'name' field")
    }
    if description == nil {
        result.errors.append("[\(skillName)] Missing required 'description' field")
    }

    guard let name = name, let description = description else {
        return nil
    }

    return SkillManifest(
        path: skillPath.path,
        name: name,
        description: description,
        author: author,
        version: version,
        lineCount: lineCount
    )
}

func validateName(_ name: String, skillName: String, result: inout ValidationResult) {
    if name.count > 64 {
        result.errors.append("[\(skillName)] name exceeds 64 characters")
    }

    let validPattern = "^[a-z0-9]+(-[a-z0-9]+)*$"
    if let regex = try? NSRegularExpression(pattern: validPattern),
       regex.firstMatch(in: name, range: NSRange(name.startIndex..., in: name)) == nil {
        result.errors.append("[\(skillName)] name contains invalid characters (use lowercase letters, numbers, hyphens)")
    }

    if name.hasPrefix("-") || name.hasSuffix("-") {
        result.errors.append("[\(skillName)] name cannot start or end with hyphen")
    }

    if name.contains("--") {
        result.errors.append("[\(skillName)] name cannot contain consecutive hyphens")
    }

    if name != skillName {
        result.errors.append("[\(skillName)] frontmatter name '\(name)' must match parent directory name '\(skillName)'")
    } else {
        result.passed.append("[\(skillName)] name '\(name)' is valid and matches directory")
    }
}

func validateDescription(_ description: String, skillName: String, result: inout ValidationResult) {
    if description.count > 1024 {
        result.errors.append("[\(skillName)] description exceeds 1024 characters")
    }

    if description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        result.errors.append("[\(skillName)] description is empty")
    }

    result.passed.append("[\(skillName)] description is valid (\(description.count) chars)")
}

func validateMetadata(author: String?, version: String?, skillName: String, result: inout ValidationResult) {
    guard let author = author, !author.isEmpty else {
        result.errors.append("[\(skillName)] Missing required 'metadata.author' field")
        return
    }
    guard let version = version, !version.isEmpty else {
        result.errors.append("[\(skillName)] Missing required 'metadata.version' field")
        return
    }
    result.passed.append("[\(skillName)] metadata is valid (author: \(author), version: \(version))")
}

func validateSections(in body: String, skillName: String, result: inout ValidationResult) {
    let requiredSections = [
        "role",
        "activation triggers",
        "core principles",
        "common tasks",
        "rejection criteria",
        "see also"
    ]

    let lines = body.components(separatedBy: "\n")
    var h2Headings: [String] = []
    var inCodeBlock = false

    for line in lines {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("```") {
            inCodeBlock.toggle()
            continue
        }
        if !inCodeBlock && trimmed.hasPrefix("## ") {
            let heading = String(trimmed.dropFirst(3))
                .trimmingCharacters(in: .whitespaces)
                .lowercased()
            h2Headings.append(heading)
        }
    }

    var lastFoundIndex = -1
    var orderValid = true
    var missingSections: [String] = []

    for required in requiredSections {
        if let idx = h2Headings.firstIndex(of: required) {
            if idx < lastFoundIndex {
                orderValid = false
            }
            lastFoundIndex = idx
        } else {
            missingSections.append(required)
        }
    }

    if !missingSections.isEmpty {
        result.errors.append("[\(skillName)] Missing required section(s): \(missingSections.joined(separator: ", "))")
    } else if !orderValid {
        result.errors.append("[\(skillName)] Required sections are out of order (expected: Role → Activation Triggers → Core Principles → ... → Common Tasks → Rejection Criteria → See Also)")
    } else {
        result.passed.append("[\(skillName)] Required sections present and in order")
    }
}

func validateRelativeLinks(in markdown: String, baseDir: URL, fileLabel: String, skillName: String, result: inout ValidationResult) {
    let fileManager = FileManager.default
    let linkPattern = #"\[([^\]]+)\]\(([^)]+)\)"#
    guard let regex = try? NSRegularExpression(pattern: linkPattern) else { return }

    let matches = regex.matches(in: markdown, range: NSRange(markdown.startIndex..., in: markdown))
    var brokenLinks: [String] = []

    for match in matches {
        guard let targetRange = Range(match.range(at: 2), in: markdown) else { continue }
        let rawTarget = String(markdown[targetRange]).trimmingCharacters(in: .whitespaces)

        if rawTarget.hasPrefix("http://") || rawTarget.hasPrefix("https://") || rawTarget.hasPrefix("mailto:") || rawTarget.hasPrefix("#") {
            continue
        }

        let pathOnly = rawTarget.components(separatedBy: "#").first ?? rawTarget
        if pathOnly.isEmpty { continue }

        let resolvedURL = baseDir.appendingPathComponent(pathOnly).standardized
        if !fileManager.fileExists(atPath: resolvedURL.path) {
            brokenLinks.append(rawTarget)
        }
    }

    if !brokenLinks.isEmpty {
        for broken in brokenLinks {
            result.errors.append("[\(skillName)] Broken relative link in \(fileLabel): '\(broken)'")
        }
    } else {
        result.passed.append("[\(skillName)] Relative links in \(fileLabel) are valid")
    }
}

func validateReferences(in path: URL, skillName: String, result: inout ValidationResult) {
    let fileManager = FileManager.default
    let refDir = path.appendingPathComponent("references")

    guard let referencesPath = try? fileManager.contentsOfDirectory(
        at: refDir,
        includingPropertiesForKeys: nil
    ) else {
        result.passed.append("[\(skillName)] No references directory (optional)")
        return
    }

    for ref in referencesPath.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
        if ref.lastPathComponent.hasPrefix(".") { continue }
        var isDir: ObjCBool = false
        if fileManager.fileExists(atPath: ref.path, isDirectory: &isDir), isDir.boolValue {
            result.errors.append("[\(skillName)] References directory contains subdirectory: \(ref.lastPathComponent) (should be flat)")
        } else if ref.pathExtension.lowercased() == "md",
                  let refContent = try? String(contentsOf: ref, encoding: .utf8) {
            validateRelativeLinks(
                in: refContent,
                baseDir: refDir,
                fileLabel: "references/\(ref.lastPathComponent)",
                skillName: skillName,
                result: &result
            )
        }
    }

    result.passed.append("[\(skillName)] References structure is valid")
}

func runSnippetVerification(at basePath: String) -> Bool {
    let scriptDirURL = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    let siblingVerifyURL = scriptDirURL.appendingPathComponent("verify-snippets.swift")
    let fallbackVerifyURL = URL(fileURLWithPath: basePath).appendingPathComponent("scripts/verify-snippets.swift")
    let verifyScriptURL = FileManager.default.fileExists(atPath: siblingVerifyURL.path) ? siblingVerifyURL : fallbackVerifyURL

    guard FileManager.default.fileExists(atPath: verifyScriptURL.path) else {
        print("✗ Cannot find \(verifyScriptURL.path)")
        return false
    }

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
    process.arguments = [
        "swift",
        "-module-cache-path", "/tmp/stratos-clang-module-cache",
        verifyScriptURL.path,
        basePath
    ]
    process.standardOutput = FileHandle.standardOutput
    process.standardError = FileHandle.standardError

    do {
        try process.run()
        process.waitUntilExit()
        return process.terminationStatus == 0
    } catch {
        print("✗ Failed to run verify-snippets.swift: \(error)")
        return false
    }
}

func printUsage() {
    print("""
    Usage: swift scripts/validate-skills.swift [options] [path]

    Options:
      --skip-snippets   Run fast structural/frontmatter/link validation only
      --snippets-only   Run Swift 6 code snippet compilation only
      -h, --help        Show this help message
    """)
}

func main() {
    let rawArgs = Array(CommandLine.arguments.dropFirst())
    let knownFlags: Set<String> = ["--skip-snippets", "--snippets-only", "--help", "-h"]
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

    let skipSnippets = flags.contains("--skip-snippets")
    let snippetsOnly = flags.contains("--snippets-only")
    let positionalArgs = rawArgs.filter { !$0.hasPrefix("-") }
    let path = positionalArgs.first ?? "."

    if snippetsOnly {
        let ok = runSnippetVerification(at: path)
        exit(ok ? 0 : 1)
    }

    print("Validating skills in: \(path)")
    print("")

    let result = validateSkills(at: path)

    print("=== PASSED ===")
    for item in result.passed {
        print("✓ \(item)")
    }

    if !result.warnings.isEmpty {
        print("")
        print("=== WARNINGS ===")
        for item in result.warnings {
            print("⚠ \(item)")
        }
    }

    if !result.errors.isEmpty {
        print("")
        print("=== ERRORS ===")
        for item in result.errors {
            print("✗ \(item)")
        }
    }

    print("")
    if !result.isSuccess {
        print("✗ Validation failed with \(result.errors.count) error(s)")
        exit(1)
    }

    if skipSnippets {
        print("✓ All structural validations passed! (skipped snippet compilation)")
        exit(0)
    }

    print("")
    let snippetsOK = runSnippetVerification(at: path)
    if snippetsOK {
        print("\n✓ All skill and code snippet validations passed!")
        exit(0)
    } else {
        exit(1)
    }
}

main()