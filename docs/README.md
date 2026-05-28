# Native Display System Documentation

Welcome to the Native Display System documentation hub. This guide helps you navigate the project's documentation resources.

---

## Documentation Organization

This project maintains documentation in multiple locations, each serving a specific purpose:

```
clevertap-native-ui-kit/
├── README.md                    # Main project README (getting started)
├── CLAUDE.md                    # Claude Code knowledge base (quick reference)
│
├── docs/                        # User-facing documentation
│   ├── README.md               # This file
│   ├── VISUAL_STRATEGY_GUIDE.md # Visual rendering approach guide
│   └── archive/                # Historical documentation
│
├── .claude/                     # Claude Code project structure
│   ├── reference/              # Technical specifications
│   ├── specs/                  # Development specifications
│   └── agents/                 # Agent-specific knowledge bases
│
├── android/docs/               # Android SDK documentation
└── ios/README.md               # iOS SDK documentation
```

---

## Quick Links

### For Users

- **[Main README](../README.md)** - Project overview, installation, quick start
- **[Visual Strategy Guide](VISUAL_STRATEGY_GUIDE.md)** - How visual rendering works
- **[Android SDK Docs](../android/docs/)** - Android implementation details
- **[iOS SDK Docs](../ios/README.md)** - iOS implementation details

### For Contributors

- **[Claude Code Knowledge Base](../CLAUDE.md)** - Quick reference for development
- **[Technical Specifications](.claude/reference/)** - Complete technical specs
- **[Agent Documentation](.claude/agents/)** - Agent-specific knowledge bases
- **[Development Specs](.claude/specs/)** - Specifications for new features

---

## Core Documentation Files

### Technical Specifications (`.claude/reference/`)

| File | Description |
|------|-------------|
| **CLAUDE_CODE_REFERENCE_ACTUAL.md** | Complete specification verified against actual code |
| **CLAUDE_CODE_PATTERNS.md** | Copy-paste ready implementation patterns |
| **CLAUDE_CODE_MODELS.md** | Type definitions for Kotlin, Swift, TypeScript |
| **COMPONENTS_GUIDE.md** | Examples for each container and element type |
| **STYLE_THEMING_GUIDE.md** | Styling system and theme usage |
| **ARCHITECTURE_INDEX.md** | Architecture documentation index |
| **LAYOUT_SEPARATION.md** | Layout system design decisions |
| **ADAPTIVE_ARCHITECTURE.md** | Adaptive architecture patterns |
| **PLATFORM_ARRANGEMENT_COMPARISON.md** | Cross-platform arrangement comparison |

### Development Specifications (`.claude/specs/`)

Active specifications for features under development. Each spec follows the standard template and includes:
- Feature overview
- API design
- Implementation approach
- Testing strategy
- Platform considerations

---

## Agent Documentation (`.claude/agents/`)

The project uses specialized Claude Code agents, each with their own knowledge base:

### Android SDK Agent (`android-sdk/`)
- **Purpose**: Android SDK implementation (Kotlin + Jetpack Compose)
- **Knowledge**: Architecture, Compose patterns, rendering pipeline, performance
- **Examples**: Container/element implementations, style resolution
- **Prompts**: Implementation templates, debugging guides

### iOS SDK Agent (`ios-sdk/`)
- **Purpose**: iOS SDK implementation (Swift + SwiftUI)
- **Knowledge**: Architecture, SwiftUI patterns, rendering pipeline, performance
- **Examples**: Container/element implementations, style resolution
- **Prompts**: Implementation templates, debugging guides

### Android Sample Agent (`android-sample/`)
- **Purpose**: Android sample application
- **Knowledge**: Sample architecture, demo patterns, integration guide
- **Examples**: Product cards, galleries, forms, arrangement demos
- **Prompts**: Demo creation, sample updates, integration testing

### iOS Sample Agent (`ios-sample/`)
- **Purpose**: iOS sample application
- **Knowledge**: Sample architecture, demo patterns, integration guide
- **Examples**: Product cards, galleries, forms, arrangement demos
- **Prompts**: Demo creation, sample updates, integration testing

### Testing Agent (`testing/`)
- **Purpose**: Automated testing, visual parity, screenshot capture
- **Knowledge**: Testing strategy, screenshot automation, visual comparison
- **Templates**: Test JSON configurations for various scenarios
- **Scripts**: Test generation, screenshot capture, visual diff reports
- **Prompts**: Test generation, visual debugging, test suite creation

---

## Platform-Specific Documentation

### Android
- Location: `android/docs/`
- Topics: Gradle setup, SDK integration, Compose rendering, best practices

### iOS
- Location: `ios/README.md`
- Topics: Swift Package Manager, SDK integration, SwiftUI rendering, best practices

---

## Archived Documentation (`docs/archive/`)

Historical documentation preserved for reference:

| File | Description |
|------|-------------|
| **layout-refactoring-summary.md** | Layout system refactoring history |
| **ios-arrangement-implementation.md** | iOS arrangement implementation notes |
| **installation-guide-legacy.md** | Legacy installation instructions |
| **architecture-install-summary.md** | Historical architecture summary |

These documents are kept for historical context but may contain outdated information. Refer to current documentation for up-to-date guidance.

---

## Documentation Workflow

### For New Features

1. Create spec in `.claude/specs/` using the template
2. Document implementation in relevant agent knowledge base
3. Update platform-specific docs (Android/iOS)
4. Add examples to agent examples directories
5. Update this README if needed

### For Bug Fixes

1. Document root cause in agent knowledge/gotchas.md
2. Update implementation patterns if needed
3. Add test cases to testing agent templates

### For Architecture Changes

1. Update `.claude/reference/ARCHITECTURE_INDEX.md`
2. Update relevant agent knowledge bases
3. Update platform-specific docs
4. Archive old documentation if superseded

---

## Need Help?

- **Getting started**: Read [Main README](../README.md)
- **Quick reference**: Check [CLAUDE.md](../CLAUDE.md)
- **Technical details**: Browse [.claude/reference/](.claude/reference/)
- **Implementation patterns**: Check agent examples in [.claude/agents/](.claude/agents/)
- **New features**: Review specs in [.claude/specs/](.claude/specs/)

---

## Contributing to Documentation

When contributing to documentation:

1. **User-facing docs** → `docs/` directory
2. **Technical specs** → `.claude/reference/`
3. **Development specs** → `.claude/specs/`
4. **Agent knowledge** → `.claude/agents/{agent-name}/knowledge/`
5. **Code examples** → `.claude/agents/{agent-name}/examples/`
6. **Platform docs** → `android/docs/` or `ios/`

Follow the existing structure and style for consistency.

---

**Last Updated**: February 2026
