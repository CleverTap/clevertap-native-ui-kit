---
name: statusline
description: Show current project status and development phase progress
user-invocable: true
disable-model-invocation: false
---

# Statusline Skill

Displays comprehensive project status including git state, development phases, recent changes, and active work items.

## Usage

```bash
# Show full status
/statusline

# Show only git status
/statusline --git

# Show only phase progress
/statusline --phase

# Show quick summary
/statusline --quick
```

## What This Skill Shows

### 1. Git Status
- Current branch
- Staged changes
- Unstaged changes
- Untracked files
- Commits ahead/behind remote
- Last commit message

### 2. Phase Progress
- Current development phase
- Active specifications
- Completed features
- Upcoming work

### 3. Build & Test Status
- Last build status (pass/fail)
- Last test run results
- Coverage metrics (if available)

### 4. Recent Activity
- Recent commits (last 5)
- Recent file changes
- Active branches

### 5. Project Health
- Outstanding TODOs
- Open issues (if tracked)
- Warnings from last build
- Uncommitted changes count

## Output Format

### Full Status
```
📊 Native Display System - Status Report
=========================================

🔀 GIT STATUS
Current Branch: feat/SDK-5405/base-components
Main Branch: main
Status: 14 files staged, 3 files modified, 2 untracked

Staged:
  A  .claude/skills/commit/SKILL.md
  A  .claude/skills/generate-json/SKILL.md
  M  .claude/README.md
  ... (11 more files)

Modified:
  M  CLAUDE.md
  M  android/sdk/src/main/kotlin/models/Container.kt
  M  ios/Sources/Models/Container.swift

Last Commit: feat: updates the claude file for JSON_REFERENCE
Commits ahead of main: 5

---

🎯 DEVELOPMENT PHASE
Current: Base Components Implementation
Spec: .claude/specs/base-components.md

Progress:
  ✅ Container types: VERTICAL, HORIZONTAL, BOX, STACK (100%)
  ✅ Element types: TEXT, IMAGE, BUTTON (100%)
  🔄 Element types: VIDEO, SPACER, DIVIDER (60%)
  ⏳ Gallery container: SNAPPING mode (0%)

---

🏗️ BUILD STATUS
Android: ✅ PASSED (45.3s ago)
  - 150 files compiled
  - 2 warnings

iOS: ✅ PASSED (23.1s ago)
  - 120 files compiled
  - 0 warnings

---

🧪 TEST STATUS
Android: ✅ 45/45 tests passed (12.3s ago)
iOS: ✅ 38/38 tests passed (8.7s ago)

Coverage:
  - Android: 91% (target: 85%)
  - iOS: 89% (target: 85%)

---

📝 RECENT COMMITS
1. 8601bc1 - feat: updates the claude file for JSON_REFERENCE (2 hours ago)
2. 9237ac0 - fix: standardize color parsing to ARGB format (3 hours ago)
3. 435c821 - feat: uses environment extension in ios app (1 day ago)
4. bc7ce4b - fix(SDK-5546): correct style cascading (1 day ago)
5. ddf63ac - feat: fixes sample app android (2 days ago)

---

⚠️ ATTENTION NEEDED
- 3 uncommitted changes in android/sdk/
- 2 TODO comments in ios/Sources/Models/
- 1 deprecation warning in android build
- README.md needs update for new features

---

📋 QUICK ACTIONS
- /build    - Build Android and iOS
- /test     - Run all tests
- /review   - Review uncommitted changes
- /commit   - Commit staged changes
```

### Quick Summary
```
📊 Status: feat/SDK-5405/base-components
🔀 Changes: 14 staged, 3 modified, 2 untracked
🏗️ Build: ✅ Android (45.3s) | ✅ iOS (23.1s)
🧪 Tests: ✅ 45 Android | ✅ 38 iOS
⚠️ Attention: 3 uncommitted, 2 TODOs
```

## Git Status Details

### Branch Information
```
Current: feat/SDK-5405/base-components
Tracking: origin/feat/SDK-5405/base-components
Behind: 0 commits
Ahead: 5 commits
```

### Change Categories

#### Staged (A = Added, M = Modified, D = Deleted)
```
A  .claude/skills/commit/SKILL.md
M  .claude/README.md
D  old-file.md
```

#### Modified (Unstaged)
```
M  CLAUDE.md
M  android/sdk/src/main/kotlin/models/Container.kt
```

#### Untracked
```
?? test-configs/new-test.json
?? docs/draft-spec.md
```

## Phase Progress Tracking

Reads from `.claude/specs/` and tracks:
- Active specification
- Implementation progress
- Completed features
- Blocked items
- Next steps

### Phase Status Indicators
- ✅ Completed (100%)
- 🔄 In Progress (1-99%)
- ⏳ Pending (0%)
- ❌ Blocked
- ⚠️ Needs Attention

## Build & Test Integration

Shows results from last:
- `/build` invocation
- `/test` invocation
- Coverage reports (if available)

### Status Indicators
- ✅ PASSED - All checks passed
- ❌ FAILED - Some checks failed
- ⚠️ WARNING - Passed with warnings
- ⏳ RUNNING - Currently executing
- ❔ UNKNOWN - No recent data

## Recent Activity

### Commits
Shows last 5 commits with:
- Short hash
- Commit message (first line)
- Time ago
- Author (if available)

### File Changes
Shows recently modified files:
- Timestamp
- File path
- Change type (added/modified/deleted)

### Active Work
Shows current work items:
- TODO comments in code
- Open specs
- Draft implementations

## Project Health Metrics

### Code Quality
- Outstanding TODO comments
- Deprecation warnings
- Lint issues (if available)

### Documentation
- Outdated docs
- Missing docs
- Doc coverage

### Dependencies
- Outdated dependencies
- Security vulnerabilities
- License issues

## Configuration

Configure in `.claude/settings.json`:
```json
{
  "statusline": {
    "showGit": true,
    "showPhase": true,
    "showBuild": true,
    "showTests": true,
    "showHealth": true,
    "recentCommitsCount": 5,
    "quickMode": false
  }
}
```

## Integration Points

### Git Integration
- Reads `.git/` directory
- Uses `git status`, `git log`, `git diff`
- Tracks branch information

### Spec Integration
- Reads `.claude/specs/` directory
- Tracks active specifications
- Shows progress from spec metadata

### Build Integration
- Checks recent build logs
- Shows build artifacts
- Reports warnings/errors

### Test Integration
- Shows test results
- Reports coverage
- Highlights failures

## Use Cases

### 1. Daily Standup
```bash
/statusline --quick
```
Quick overview of what's done, in progress, and blocked

### 2. Before Commit
```bash
/statusline --git
```
Review what will be committed

### 3. After Implementation
```bash
/statusline
```
Full status to verify everything is complete

### 4. Sprint Review
```bash
/statusline --phase
```
Show phase progress and completed work

## Customization

### Custom Status Sections
Add to `.claude/statusline-custom.md`:
```markdown
## Custom Metrics
- API response time: 45ms (target: <100ms)
- Bundle size: 234KB (target: <300KB)
- Memory usage: 45MB (target: <60MB)
```

### Custom Health Checks
Add to `.claude/statusline-health.sh`:
```bash
#!/bin/bash
# Check for large files
find . -size +1M -not -path "./.git/*"
```

## Automation

### Pre-Commit Hook
Show status before commit:
```bash
#!/bin/bash
# .git/hooks/pre-commit
/statusline --git
```

### CI/CD Integration
Report status in CI:
```yaml
- name: Status Report
  run: /statusline --quick
```

## Advanced Features

### Historical Tracking
Track status over time:
```
.claude/status-history/
├── 2024-01-15-status.json
├── 2024-01-16-status.json
└── 2024-01-17-status.json
```

### Trend Analysis
Show trends:
- Build time trends
- Test coverage trends
- Commit frequency
- Issue resolution time

### Team Dashboard
Generate team-wide status:
```bash
/statusline --team
```

### Export Formats
Export status to:
- JSON for scripts
- Markdown for docs
- HTML for dashboards
- Slack/Discord for notifications

## Best Practices

1. **Check status regularly** - Stay aware of project state
2. **Review before committing** - Verify what's being committed
3. **Track phase progress** - Know where you are in development
4. **Monitor health metrics** - Catch issues early
5. **Share status** - Keep team informed

## Related Skills

- `/commit` - Commit after verifying status
- `/build` - Build to update build status
- `/test` - Test to update test status
- `/review` - Review to check code quality

## Troubleshooting

### "Git not found"
Ensure git is installed and in PATH

### "Cannot read spec progress"
Ensure `.claude/specs/` contains spec files with progress metadata

### "Build status unavailable"
Run `/build` to generate build status

### "Test status unavailable"
Run `/test` to generate test status

## Performance

Status generation is fast:
- Git status: <100ms
- Phase progress: <50ms
- Build status: <50ms
- Total: <300ms

Cached where possible for faster subsequent calls.
