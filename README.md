# Stratos

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.0-blue.svg)](stratos-core/SKILL.md)

AI Agent Skills for High-End API Design following the principle of Progressive Disclosure.

## Skills

| Skill | Role | Description |
|-------|------|-------------|
| **stratos-core** | The Architect | The architectural laws and methodology |
| **stratos-swiftui** | The Component Designer | SwiftUI component designer skill |
| **stratos-swift** | The SDK Engineer | SDK engineer skill for Swift libraries |

## Installation

```bash
npx skills add peterfriese/Stratos@stratos-core
npx skills add peterfriese/Stratos@stratos-swiftui
npx skills add peterfriese/Stratos@stratos-swift
```

## Philosophy

Stratos follows the principle of **Progressive Disclosure** — APIs should be simple to use by default but "unfold" their complexity only when explicitly required.

See [stratos-core/SKILL.md](stratos-core/SKILL.md) for the full methodology.

## Quick Start

**When to use each skill:**

- **stratos-core**: When designing APIs, reviewing code quality, or discussing Progressive Disclosure principles
- **stratos-swiftui**: When building reusable SwiftUI components, ViewModifiers, or custom Styles
- **stratos-swift**: When creating Swift libraries, SDKs, or implementing Swift 6 concurrency patterns

## Further Reading

- [The craft of SwiftUI API design: Progressive disclosure](https://developer.apple.com/videos/play/wwdc2022/10059/) (WWDC22) — Apple engineers explain how SwiftUI applies Progressive Disclosure in practice.
- [On Progressive Disclosure in Swift](https://www.youtube.com/watch?v=opqKGgJavkw) (Swift Craft 2025) — Doug Gregor explains how Swift applies Progressive Disclosure as a language design principle.