# Quick Reference: Your 7 Agents

Cheat sheet. Full guide → [`AGENTS_README.md`](AGENTS_README.md).

---

## Agent cheat sheet

| Agent | Primary use |
|-------|-------------|
| `android-sdk` | Android (Kotlin/Compose) SDK implementation |
| `ios-sdk` | iOS (Swift/SwiftUI) SDK implementation |
| `flutter-sdk` | Flutter (Dart) plugin implementation |
| `android-sample` | Android demos (Compose + XML) |
| `ios-sample` | iOS demos (SwiftUI) |
| `flutter-sample` | Flutter demos |
| `testing` | Test gen + build/run automation + cross-platform screenshots |

Invoke by naming the agent, e.g. `"Using the <agent> agent, …"`.

---

## Quick commands

### Implementation (parallel across platforms)
```
Using the android-sdk agent, implement GRID from spec 013
Using the ios-sdk agent, implement GRID from spec 013
Using the flutter-sdk agent, implement GRID from spec 013
```

### Demos
```
Using the android-sample agent, create a product-card demo
Using the ios-sample agent, create a product-card demo
Using the flutter-sample agent, create a product-card demo
```

### Testing, automation & screenshots
```
Using the testing agent, generate 25 container test variations
Using the testing agent, run /nd-screenshot-compare on Android + iOS
Using the testing agent, pair screenshots by event and report diffs
```

### Bug fixes & review
```
Using the flutter-sdk agent, fix GALLERY peek sizing in native_display_view.dart
Using the android-sdk agent, review NativeDisplayRenderer.kt for recomposition cost
```

---

## File locations

```
.claude/
├── AGENTS_README.md            ← full agent guide
├── AGENTS_QUICK_REFERENCE.md   ← this cheat sheet
├── agents/<name>.md            ← each agent definition
└── agents/<name>/knowledge/    ← each agent's architecture + patterns
```

---

## Common workflows

| Goal | Flow |
|------|------|
| Full feature | spec → android-sdk → ios-sdk + flutter-sdk (parallel) → sample agents → testing |
| Bug fix | testing (repro) → owning SDK agent (fix) → testing (validate) |
| Parity check | testing → /nd-screenshot-compare → route diffs to SDK agents |

---

## Pro tips
- Be specific — name files and line numbers.
- Reference the spec or ticket.
- Fan out SDK agents in parallel for cross-platform work; Android is the reference.
- Always review agent output before committing.
