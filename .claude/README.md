# .claude Directory

This directory contains AI agent configurations and documentation for the Native Display UI Kit project.

---

## 📂 Structure

```
.claude/
├── README.md              # This file
├── PROGRESS.md            # Development phase tracking
├── settings.json          # Project configuration
│
├── skills/                # 6 Project skills (NEW)
│   ├── commit/            # Git commit automation
│   ├── generate-json/     # Test JSON generation
│   ├── test/              # Test execution
│   ├── build/             # Build automation
│   ├── review/            # Code review
│   └── statusline/        # Project status
│
├── agents/                # 5 Specialized AI agents
│   ├── README.md          # Agents overview
│   ├── QUICK_REFERENCE.md # Agent command cheat sheet
│   ├── android-sdk/       # Android SDK agent
│   ├── ios-sdk/           # iOS SDK agent
│   ├── android-sample/    # Android sample agent
│   ├── ios-sample/        # iOS sample agent
│   └── testing/           # Testing & automation agent
│
├── reference/             # SDK documentation (phases 1-8)
│   ├── CLAUDE_CODE_REFERENCE_ACTUAL.md
│   ├── CLAUDE_CODE_PATTERNS.md
│   ├── COMPONENTS_GUIDE.md
│   ├── STYLE_THEMING_GUIDE.md
│   └── CLAUDE_CODE_MODELS.md
│
└── specs/                 # Feature specifications (phase 9+)
    ├── TEMPLATE.md
    ├── README.md
    └── [spec files]
```

---

## 🤖 AI Agents

We have **5 specialized agents** to help with development:

| Agent | Handle | Purpose |
|-------|--------|---------|
| **Android SDK** | `@android-sdk-agent` | Implement Android features |
| **iOS SDK** | `@ios-sdk-agent` | Implement iOS features |
| **Android Sample** | `@android-sample-agent` | Create Android demos |
| **iOS Sample** | `@ios-sample-agent` | Create iOS demos |
| **Testing** | `@testing-agent` | Generate tests & screenshots |

**See**: `agents/README.md` for full details

---

## 🛠️ Skills

**Skills** are one-command workflows that automate common tasks. Invoke with `/skill-name`.

### Available Skills

| Skill | Command | Purpose | Example |
|-------|---------|---------|---------|
| **Commit** | `/commit` | Create git commit with proper message | `/commit` |
| **Generate JSON** | `/generate-json` | Generate test JSON configs | `/generate-json product-card` |
| **Test** | `/test` | Run Android/iOS tests | `/test android` |
| **Build** | `/build` | Build Android/iOS SDK | `/build ios` |
| **Review** | `/review` | Review code changes | `/review` |
| **Statusline** | `/statusline` | Show project status | `/statusline` |

### Skill Workflows

#### Making Changes
```
1. Edit code
2. /build        → Verify compilation
3. /test         → Run tests
4. /review       → Check standards
5. /commit       → Commit changes
```

#### Generating Test Configs
```
1. /generate-json container-test
   → Creates valid JSON following JSON_STRUCTURE_REFERENCE.md
   → Validates colors (ARGB format)
   → Ensures layout definitions
   → Runs jq validation
```

#### Quick Status Check
```
/statusline
   → Git status
   → Build status
   → Test results
   → Phase progress
```

### Skills Benefits

- ✅ **Fast workflows** - One command instead of multiple steps
- ✅ **Consistency** - Same process every time
- ✅ **Validation** - Built-in checks and standards
- ✅ **Discoverability** - Easy to remember `/skill-name` pattern
- ✅ **Integration** - Work seamlessly with agents

**See**: Each skill's `SKILL.md` file in `skills/` directory for detailed documentation

---

## 📚 Documentation

### For Existing Features (Phases 1-8)
→ Check `reference/` directory

### For New Features (Phase 9+)
→ Check `specs/` directory

---

## 🚀 Quick Start

### Using Agents
```
"@testing-agent, generate 10 container tests"
"@android-sdk-agent, implement GRID from spec 013"
"@ios-sdk-agent, ensure cross-platform parity for GALLERY"
```

### Writing Specs
```
1. Copy specs/TEMPLATE.md
2. Fill in requirements
3. Implement with agents
```

---

## 📋 What's What

- **skills/**: One-command workflows for common tasks (NEW)
- **agents/**: AI agent configurations and documentation
- **reference/**: Documentation for implemented features
- **specs/**: Specifications for new features
- **PROGRESS.md**: Phase completion tracking
- **settings.json**: Build commands, paths, conventions

---

**Last Updated**: January 20, 2026  
**Agent Count**: 5  
**Status**: Operational
