# Agents Directory

This directory contains specialized AI agents for the Native Display UI Kit.

---

## 🤖 Available Agents

### 1. Android SDK Agent (`android-sdk/`)
**Expertise**: Android implementation, Jetpack Compose, Kotlin
**Scope**: `android/sdk/` - SDK implementation
**Use for**: Implementing Android features, fixing bugs, optimizing, testing

### 2. iOS SDK Agent (`ios-sdk/`)
**Expertise**: iOS implementation, SwiftUI, Swift
**Scope**: `ios/Sources/` - SDK implementation
**Use for**: Implementing iOS features, fixing bugs, optimizing, testing

### 3. Android Sample Agent (`android-sample/`)
**Expertise**: Android sample apps (Compose + XML)
**Scope**: `android-sample/` + `android-xml-sample/`
**Use for**: Creating demos, updating samples, integration examples

### 4. iOS Sample Agent (`ios-sample/`)
**Expertise**: iOS sample app (SwiftUI)
**Scope**: `ios-sample/`
**Use for**: Creating demos, updating samples, integration examples

### 5. Testing Agent (`testing/`)
**Expertise**: Test generation, screenshot automation, visual comparison
**Scope**: All platforms
**Use for**: Generating test JSON, capturing screenshots, comparing results

---

## 🎯 How to Use Agents

### Direct Agent Usage
```
"@android-sdk-agent, implement GRID container from spec 013"
"@ios-sdk-agent, fix memory leak in ImageRenderer"
"@android-sample-agent, create product card demo"
"@ios-sample-agent, add login form example"
"@testing-agent, generate 20 container test variations"
```

### Collaborative Usage
```
"@testing-agent, generate tests for GALLERY containers"
"@android-sdk-agent and @ios-sdk-agent, implement those tests"
"@testing-agent, capture screenshots and compare"
```

---

## 📂 Directory Structure

```
agents/
├── README.md                  # This file
│
├── android-sdk/               # Android SDK Agent
│   ├── AGENT.md               # Agent identity
│   ├── knowledge/             # Android expertise
│   ├── prompts/               # Reusable prompts
│   └── examples/              # Code examples
│
├── ios-sdk/                   # iOS SDK Agent
│   ├── AGENT.md
│   ├── knowledge/
│   ├── prompts/
│   └── examples/
│
├── android-sample/            # Android Sample Agent
│   ├── AGENT.md
│   ├── knowledge/
│   ├── prompts/
│   └── examples/
│
├── ios-sample/                # iOS Sample Agent
│   ├── AGENT.md
│   ├── knowledge/
│   ├── prompts/
│   └── examples/
│
└── testing/                   # Testing Agent
    ├── AGENT.md
    ├── knowledge/
    ├── templates/             # JSON test templates
    ├── scripts/               # Automation scripts
    └── output/                # Generated tests & screenshots
```

---

## 🚀 Quick Start

### Running Tests
```bash
# Generate test JSON
cd agents/testing
./scripts/generate-tests.sh --category containers --count 25

# Capture Android screenshots
./scripts/capture-android.sh

# Capture iOS screenshots
./scripts/capture-ios.sh

# Compare results
./scripts/compare.sh --output report.html
```

### Implementing Features
```bash
# 1. Create spec
cd ../../specs
cp TEMPLATE.md 013-grid-container.md
# Edit spec...

# 2. Implement on Android
# Ask: "@android-sdk-agent, implement spec 013"

# 3. Implement on iOS
# Ask: "@ios-sdk-agent, implement spec 013"

# 4. Add samples
# Ask: "@android-sample-agent, create demo for GRID"
# Ask: "@ios-sample-agent, create demo for GRID"
```

---

## 📚 Agent Documentation

Each agent has its own `AGENT.md` file with:
- Identity and role
- Expertise areas
- Knowledge sources
- Capabilities and limitations
- Interaction patterns
- Example queries

Read the agent's `AGENT.md` before interacting with it.

---

## 🔄 Agent Workflow Examples

### Example 1: New Feature Implementation
```
1. You create spec in ../specs/
2. @android-sdk-agent implements Android
3. @ios-sdk-agent implements iOS
4. @testing-agent generates tests
5. @testing-agent runs tests and reports results
6. Agents fix any issues found
7. @android-sample-agent adds demo
8. @ios-sample-agent adds demo
```

### Example 2: Bug Fix
```
1. You report bug: "RTL layout broken in HORIZONTAL containers"
2. @testing-agent creates reproduction test case
3. @android-sdk-agent analyzes and fixes
4. @testing-agent validates fix with screenshot comparison
5. @android-sample-agent updates relevant demos
```

### Example 3: Cross-Platform Validation
```
1. @testing-agent generates comprehensive test suite
2. @testing-agent captures screenshots on both platforms
3. @testing-agent generates comparison report
4. @android-sdk-agent fixes Android-specific issues
5. @ios-sdk-agent fixes iOS-specific issues
6. @testing-agent re-runs and validates fixes
```

---

## 💡 Best Practices

### 1. Be Specific
❌ "Fix the layout"
✅ "@android-sdk-agent, fix RTL layout in HorizontalContainer.kt line 142"

### 2. Reference Context
❌ "Implement the feature"
✅ "@ios-sdk-agent, implement GRID container from spec 013"

### 3. Provide Test Cases
❌ "It's broken"
✅ "@testing-agent, create test case: VERTICAL with 10 children and negative margin"

### 4. Use Collaboration
❌ Ask one agent to do everything
✅ "@testing-agent generate, @android-sdk-agent implement, @testing-agent validate"

### 5. Review Agent Output
Always review and test agent-generated code before merging

---

## ⚠️ Limitations

### What Agents CAN Do
- Generate code following existing patterns
- Fix bugs with clear reproduction steps
- Create test cases and demos
- Analyze and compare implementations
- Optimize performance with guidance

### What Agents CANNOT Do
- Make architectural decisions without guidance
- Access production systems
- Deploy code automatically
- Make breaking changes without approval
- Override safety constraints

---

## 🛠️ Maintenance

### Updating Agent Knowledge
When you make significant changes:
1. Update relevant agent's `knowledge/` docs
2. Add new patterns to `examples/`
3. Update `AGENT.md` if capabilities change

### Adding New Agents
1. Create new directory in `agents/`
2. Copy structure from existing agent
3. Write `AGENT.md`
4. Add knowledge docs
5. Update this README

---

## 📞 Support

- Agent not working? Check its `AGENT.md` for limitations
- Need new capability? Update agent's knowledge base
- Agent giving wrong answers? Improve its knowledge docs
- Want new agent? Follow "Adding New Agents" above

---

**Last Updated**: January 20, 2026  
**Agent Count**: 5  
**Status**: Active
