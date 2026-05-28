# Quick Reference: Your 5 Agents

---

## 🤖 Agent Cheat Sheet

| Agent | Handle | Primary Use |
|-------|--------|-------------|
| **Android SDK** | `@android-sdk-agent` | Android implementation |
| **iOS SDK** | `@ios-sdk-agent` | iOS implementation |
| **Android Sample** | `@android-sample-agent` | Android demos |
| **iOS Sample** | `@ios-sample-agent` | iOS demos |
| **Testing** | `@testing-agent` | Tests & screenshots |

---

## 💬 Quick Commands

### Testing
```
@testing-agent, generate 25 container tests
@testing-agent, capture Android screenshots for all tests
@testing-agent, capture iOS screenshots for all tests
@testing-agent, compare and generate report
```

### Implementation
```
@android-sdk-agent, implement GRID from spec 013
@ios-sdk-agent, implement GRID from spec 013
```

### Demos
```
@android-sample-agent, create product card demo
@ios-sample-agent, create product card demo
```

### Bug Fixes
```
@android-sdk-agent, fix RTL layout in HorizontalContainer.kt
@ios-sdk-agent, fix shadow rendering on iOS 14
```

### Code Review
```
@android-sdk-agent, review ContainerRenderer.kt for performance
@ios-sdk-agent, review ContainerRenderer.swift for memory leaks
```

---

## 📂 File Locations

```
.claude/agents/
├── README.md                  ← Start here
├── AGENTS_READY.md            ← Setup complete guide
├── android-sdk/AGENT.md       ← Android SDK agent details
├── ios-sdk/AGENT.md           ← iOS SDK agent details
├── android-sample/AGENT.md    ← Android sample agent details
├── ios-sample/AGENT.md        ← iOS sample agent details
└── testing/AGENT.md           ← Testing agent details
```

---

## 🎯 Common Workflows

### Full Feature Implementation
```
1. @testing-agent, generate tests for GRID
2. @android-sdk-agent, implement GRID
3. @ios-sdk-agent, implement GRID
4. @testing-agent, validate with screenshots
5. @android-sample-agent, add GRID demo
6. @ios-sample-agent, add GRID demo
```

### Bug Fix & Validation
```
1. @testing-agent, create repro test for [bug]
2. @android-sdk-agent or @ios-sdk-agent, fix bug
3. @testing-agent, validate fix with screenshots
```

### Cross-Platform Parity Check
```
1. @testing-agent, generate comprehensive test suite
2. @testing-agent, capture both platforms
3. @testing-agent, compare and report
4. @android-sdk-agent & @ios-sdk-agent, fix differences
```

---

## ⚡ Pro Tips

- **Be specific**: Include file names and line numbers
- **Provide context**: Reference specs, issues, or previous work
- **Use collaboration**: Multiple agents working together
- **Review output**: Always check agent work before committing

---

**Read full docs**: `.claude/agents/AGENTS_READY.md`
