#!/usr/bin/env swift

import Foundation

enum ValidationError: Error {
    case invalidName(String)
    case invalidDescription(String)
    case missingFile(String)
    case invalidStructure(String)
    case deepReference(String)
}

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
    let lineCount: Int
}

func validateSkills(at basePath: String) -> ValidationResult {
    var result = ValidationResult()

    let fileManager = FileManager.default
    let baseURL = URL(fileURLWithPath: basePath)

    guard let contents = try? fileManager.contentsOfDirectory(
        at: baseURL,
        includingPropertiesForKeys: nil
    ) else {
        result.errors.append("Cannot read directory: \(basePath)")
        return result
    }

    var skillDirs: [URL] = []
    for item in contents {
        let isDir = (try? item.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
        if isDir {
            let skillPath = item.appendingPathComponent("SKILL.md")
            if fileManager.fileExists(atPath: skillPath.path) {
                skillDirs.append(item)
            }
        }
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
    result.passed.append("[\(name)] SKILL.md has \(lines.count) lines")

    if lines.count > 500 {
        result.warnings.append("[\(name)] SKILL.md has \(lines.count) lines (recommend <500)")
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
    let manifest = parseFrontmatter(frontmatter, skillName: name, result: &result)

    if let manifest = manifest {
        validateName(manifest.name, skillName: name, result: &result)
        validateDescription(manifest.description, skillName: name, result: &result)
    }

    validateReferences(in: path, skillName: name, result: &result)

    return result
}

func parseFrontmatter(_ yaml: String, skillName: String, result: inout ValidationResult) -> SkillManifest? {
    var name: String?
    var description: String?

    let yamlLines = yaml.components(separatedBy: "\n")
    var i = 0

    while i < yamlLines.count {
        let line = yamlLines[i]
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        // Skip empty lines and comments
        if trimmed.isEmpty || trimmed.hasPrefix("#") {
            i += 1
            continue
        }

        // Match key: value pattern
        let keyValuePattern = #"^(\w+):\s*(.*)$"#
        if let regex = try? NSRegularExpression(pattern: keyValuePattern),
           let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)) {

            if let keyRange = Range(match.range(at: 1), in: trimmed) {
                let key = String(trimmed[keyRange]).lowercased()

                // Get the value part after the colon
                var value = ""
                if let valueRange = Range(match.range(at: 2), in: trimmed) {
                    value = String(trimmed[valueRange])
                }

                // Check if this is a multiline value (starts with | or >)
                let isMultiline = value.hasPrefix("|") || value.hasPrefix(">")

                if isMultiline {
                    // Collect all indented lines that belong to this value
                    var multilineContent: [String] = []

                    // The first line after | or > contains the first line of content
                    // Strip the | or > and any leading whitespace indicator
                    let indicator = value.hasPrefix("|") ? "|" : ">"
                    let firstLine = value.replacingOccurrences(of: indicator, with: "")
                        .trimmingCharacters(in: .whitespaces)
                    if !firstLine.isEmpty {
                        multilineContent.append(firstLine)
                    }

                    // Collect subsequent indented lines
                    i += 1
                    while i < yamlLines.count {
                        let nextLine = yamlLines[i]
                        // Check if line is indented (starts with whitespace)
                        if nextLine.hasPrefix(" ") || nextLine.hasPrefix("\t") {
                            multilineContent.append(nextLine.trimmingCharacters(in: .whitespacesAndNewlines))
                            i += 1
                        } else if nextLine.trimmingCharacters(in: .whitespaces).isEmpty {
                            // Allow empty lines in multiline
                            i += 1
                        } else {
                            // Non-indented line - end of multiline value
                            break
                        }
                    }

                    value = multilineContent.joined(separator: " ")
                } else {
                    // Single-line value
                    value = value.trimmingCharacters(in: .whitespaces)
                    i += 1
                }

                // Trim trailing whitespace and newlines from value
                value = value.trimmingCharacters(in: .whitespacesAndNewlines)

                if key == "name" {
                    name = value
                } else if key == "description" {
                    description = value
                }
            } else {
                i += 1
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

    let skillPath = "stratos-universe/\(skillName)/SKILL.md"
    let lineCount = (try? String(contentsOf: URL(fileURLWithPath: skillPath), encoding: .utf8))?
        .components(separatedBy: "\n").count ?? 0

    return SkillManifest(path: skillPath, name: name, description: description, lineCount: lineCount)
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

    result.passed.append("[\(skillName)] name '\(name)' is valid")
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

func validateReferences(in path: URL, skillName: String, result: inout ValidationResult) {
    let fileManager = FileManager.default

    guard let referencesPath = try? fileManager.contentsOfDirectory(
        at: path.appendingPathComponent("references"),
        includingPropertiesForKeys: nil
    ) else {
        result.passed.append("[\(skillName)] No references directory (optional)")
        return
    }

    for ref in referencesPath {
        var isDir: ObjCBool = false
        if fileManager.fileExists(atPath: ref.path, isDirectory: &isDir), isDir.boolValue {
            result.errors.append("[\(skillName)] References directory contains subdirectory: \(ref.lastPathComponent) (should be flat)")
        }
    }

    result.passed.append("[\(skillName)] References structure is valid")
}

func main() {
    let args = CommandLine.arguments

    var path = "."
    if args.count > 1 {
        path = args[1]
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
    if result.isSuccess {
        print("✓ All validations passed!")
        exit(0)
    } else {
        print("✗ Validation failed with \(result.errors.count) error(s)")
        exit(1)
    }
}

main()