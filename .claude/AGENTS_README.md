# Agents Guide

Specialized AI subagents for the CleverTap Native Display UI Kit. Definitions live in
[`agents/`](agents/); the portable roster is in the repo-root [`AGENTS.md`](../AGENTS.md).

---

## The 7 agents

| # | Agent | Expertise | Scope |
|---|-------|-----------|-------|
| 1 | `android-sdk` | Android SDK — Jetpack Compose, Kotlin | `android/sdk/` |
| 2 | `ios-sdk` | iOS SDK — SwiftUI, Swift | `ios/Sources/` |
| 3 | `flutter-sdk` | Flutter plugin — pure-Dart renderer (no platform channels) | `flutter/lib/` |
| 4 | `android-sample` | Android sample apps (Compose + XML) | `android-sample/`, `android-xml-sample/` |
| 5 | `ios-sample` | iOS sample app (SwiftUI) | `ios-sample/` |
| 6 | `flutter-sample` | Flutter sample app | `flutter-sample/` |
| 7 | `testing` | Test & automation + screenshot expert — JSON generation, build/run apps, drive integration/instrumentation tests, deterministic capture, comparable cross-platform screenshots | all platforms |

Each agent's directory contains its definition (`<name>.md` at `agents/`) plus a
`knowledge/` folder (architecture, patterns, gotchas, performance), and where useful
`examples/`, `prompts/`, `templates/`, `scripts/`. **An agent reads its own knowledge files
on demand** — it does not load them all upfront.

---

## How to invoke

These are Claude Code subagents — invoke by naming the agent in your request:

```
"Using the android-sdk agent, implement the GRID container from spec 013"
"Using the flutter-sdk agent, implement the GALLERY container in Dart"
"Using the testing agent, generate 25 GALLERY container test variations"
"Using the testing agent, capture & compare screenshots across Flutter/native on Android + iOS"
```

---

## Directory layout

```
agents/
├── android-sdk.md                 # Agent definition (frontmatter + system prompt)
├── android-sdk/
│   ├── knowledge/                 # architecture, compose-patterns, gotchas, performance, rendering-pipeline
│   └── examples/                  # reference Kotlin snippets
├── ios-sdk.md        + ios-sdk/{knowledge,examples}
├── flutter-sdk.md    + flutter-sdk/{knowledge,examples}
├── android-sample.md + android-sample/{knowledge,prompts,examples}
├── ios-sample.md     + ios-sample/{knowledge,examples}
├── flutter-sample.md + flutter-sample/knowledge
└── testing.md        + testing/{knowledge,prompts,templates,scripts}
```

> The hands-on screenshot automation (capture + segregate) lives in the
> [`skills/nd-screenshot-compare/`](skills/nd-screenshot-compare/) skill, which the `testing`
> agent drives — not in `agents/testing/scripts/`.

---

## Workflows

### New cross-platform feature (fan out in parallel)
```
1. Write spec in specs/ (copy TEMPLATE.md)
2. android-sdk  → implement reference behaviour
3. ios-sdk + flutter-sdk → implement to parity, in parallel, each reading its own arch file
4. android-sample / ios-sample / flutter-sample → add demos
5. testing → generate JSON, run apps, capture & compare screenshots
6. /build → /test → /review → /commit
```

### Bug fix & validation
```
1. testing → create a reproduction JSON / test case
2. android-sdk | ios-sdk | flutter-sdk → fix in the owning platform
3. testing → re-run and confirm with a screenshot diff
4. owning sample agent → update affected demos
```

### Cross-platform parity check
```
1. testing → /nd-screenshot-compare across Flutter/native (+ RN) on Android + iOS
2. Review ~/Desktop/nd-screenshots-review/<os>/<event>/<framework>.png side-by-side
3. Route each diff to the owning SDK agent (remember: content can legitimately differ
   per platform via dashboard A/B — confirm before filing a render bug)
```

---

## Collaboration rules

- SDK agents do **not** touch sample apps; sample agents do **not** touch SDK code — delegate.
- The `testing` agent does **not** fix bugs — it reproduces and hands off to the SDK agent.
- Cross-platform features require `android-sdk` **and** `ios-sdk` **and** `flutter-sdk`.
- `flutter-sdk` owns `flutter/lib/` — a pure-Dart package with no platform channels; CleverTap
  attribution flows through host callbacks forwarded to `clevertap_plugin`, not a native bridge.
- Android is the behavioural source of truth; iOS and Flutter match it.

---

## Maintenance

When capabilities change: update the agent's `<name>.md` and its `knowledge/` docs, then
keep the roster consistent across this file, [`AGENTS_QUICK_REFERENCE.md`](AGENTS_QUICK_REFERENCE.md),
[`README.md`](README.md), and the root [`AGENTS.md`](../AGENTS.md) / [`CLAUDE.md`](../CLAUDE.md).
