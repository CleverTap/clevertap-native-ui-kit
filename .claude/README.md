# .claude Directory

AI agent configuration and documentation for the CleverTap Native Display UI Kit.

> **Start here:** the repo-root [`AGENTS.md`](../AGENTS.md) is the portable entry point and
> [`CLAUDE.md`](../CLAUDE.md) is the canonical, in-depth knowledge base. This directory holds
> the agents, skills, references, and specs those files point to.

---

## Structure

```
.claude/
├── README.md                  # This file
├── AGENTS_README.md           # Full agent guide (roster, workflows, collaboration)
├── AGENTS_QUICK_REFERENCE.md  # Agent cheat sheet
├── PROGRESS.md / OPEN_POINTS.md
├── settings.json              # Project configuration
│
├── agents/                    # 7 specialized subagents (see below)
├── skills/                    # 8 one-command workflows (/skill-name)
├── reference/                 # Deep SDK references (read on demand)
└── specs/                     # Feature specifications (spec-driven workflow)
```

---

## Agents (7)

Each agent has frontmatter + a system prompt and reads its own
`agents/<name>/knowledge/architecture.md` on demand, so cross-platform features can be
built in parallel against one shared spec.

| Agent | Scope |
|-------|-------|
| `android-sdk` | `android/sdk/` — Kotlin/Compose SDK |
| `ios-sdk` | `ios/Sources/` — Swift/SwiftUI SDK |
| `flutter-sdk` | `flutter/lib/` — Dart renderer + bridge |
| `android-sample` | `android-sample/` + `android-xml-sample/` |
| `ios-sample` | `ios-sample/` |
| `flutter-sample` | `flutter-sample/` |
| `testing` | all platforms — test generation + build/run automation + cross-platform screenshots |

Full details → [`AGENTS_README.md`](AGENTS_README.md) · cheat sheet →
[`AGENTS_QUICK_REFERENCE.md`](AGENTS_QUICK_REFERENCE.md).

**Invoke explicitly**, e.g. `"Using the ios-sdk agent, ensure GALLERY parity with Android"`.

---

## Skills (8)

One-command workflows. Invoke with `/skill-name`; each has a `SKILL.md`.

| Skill | Purpose |
|-------|---------|
| `/build [android\|ios\|flutter]` | Build SDK or sample apps |
| `/test [android\|ios\|flutter]` | Run tests |
| `/generate-json [type]` | Generate valid JSON test configs |
| `/nd-screenshot-compare` | Capture & compare cross-platform screenshots |
| `/review` | Review code against project standards |
| `/commit` | Create a properly formatted git commit |
| `/ship-jira` | Create/transition the Jira ticket for committed work |
| `/statusline` | Show git, build, and test status |

---

## Documentation

- **Implementing an existing feature / verifying schema** → `reference/`
- **Starting a new feature** → `specs/` (copy `TEMPLATE.md`)
- **Phase tracking / open questions** → `PROGRESS.md`, `OPEN_POINTS.md`

---

## Maintenance

When the agent roster, skills, or workflow change, update **four** places so they stay in
sync: this file, [`AGENTS_README.md`](AGENTS_README.md),
[`AGENTS_QUICK_REFERENCE.md`](AGENTS_QUICK_REFERENCE.md), and the roster/skills tables in
[`../AGENTS.md`](../AGENTS.md) + [`../CLAUDE.md`](../CLAUDE.md).
