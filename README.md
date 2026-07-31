# Stratos

[![License](https://img.shields.io/badge/License-Apache%202.0-0a0a0a?labelColor=000000)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.1-0a0a0a?labelColor=000000)](stratos-core/SKILL.md)
[![skills.sh](https://skills.sh/b/peterfriese/Stratos)](https://skills.sh/peterfriese/Stratos)

AI Agent Skills for High-End API Design following the principle of Progressive Disclosure.

## Skills

| Skill | Role | Description |
|-------|------|-------------|
| **stratos-core** | The Architect | The architectural laws and methodology |
| **stratos-swiftui** | The Component Designer | SwiftUI component designer skill |
| **stratos-swift** | The SDK Engineer | SDK engineer skill for Swift libraries |

## Installation

### Install all skills

```bash
npx skills add peterfriese/Stratos
```

This will prompt you to select which skills to install.

### Install individual skills

```bash
# Core methodology
npx skills add peterfriese/Stratos@stratos-core

# SwiftUI components
npx skills add peterfriese/Stratos@stratos-swiftui

# Swift libraries
npx skills add peterfriese/Stratos@stratos-swift
```

### Luca

```bash
luca install peterfriese/Stratos
```

## Philosophy

Stratos follows the principle of **Progressive Disclosure** — APIs should be simple to use by default but "unfold" their complexity only when explicitly required.

See [stratos-core/SKILL.md](stratos-core/SKILL.md) for the full methodology.

## Quick start

**When to use each skill:**

- **stratos-core**: When designing APIs, reviewing code quality, or discussing Progressive Disclosure principles
- **stratos-swiftui**: When building reusable SwiftUI components, ViewModifiers, or custom Styles
- **stratos-swift**: When creating Swift libraries, SDKs, or implementing Swift 6 concurrency patterns

## What's new in 1.1

**2026-07-25:** Aligned stratos-swiftui with Apple's Xcode 27 guidance.

- `@MainActor` added to `@Observable` examples for Swift 6 concurrency safety
- Replaced manual `EnvironmentKey` boilerplate with modern `@Entry` macro
- Replaced deprecated APIs: `.foregroundColor` → `.foregroundStyle`, `.cornerRadius` → `.clipShape(RoundedRectangle(...))`
- Added rejection criteria for `.if()` conditional modifier anti-pattern
- Added SDK 27 compatibility notes (`@State` macro migration, `@ContentBuilder` unification)
- Added `@Animatable` macro and `@Observable`+`Equatable` guidance

See [docs/JOURNAL.md](docs/JOURNAL.md) for the full change log.

## Further reading

- [The craft of SwiftUI API design: Progressive disclosure](https://developer.apple.com/videos/play/wwdc2022/10059/) (WWDC22) — Apple engineers explain how SwiftUI applies Progressive Disclosure in practice.
- [On Progressive Disclosure in Swift](https://www.youtube.com/watch?v=opqKGgJavkw) (Swift Craft 2025) — Doug Gregor explains how Swift applies Progressive Disclosure as a language design principle.