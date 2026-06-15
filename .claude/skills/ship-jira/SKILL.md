---
name: ship-jira
description: Full Jira-tracked change workflow — create/select Jira ticket under epic SDK-5256, create feat/SDK-XXXX branch, commit with ticket id, push, and open PR with ticket id in title and Jira links in body
user-invocable: true
disable-model-invocation: false
---

# Ship Jira Skill

End-to-end workflow for any tracked change to this repo. Every change ships through Jira: ticket → branch → commit → push → PR. The ticket id is in the branch name, commit subject, and PR title.

## Usage

```
/ship-jira [SDK-XXXX]                  # use existing ticket
/ship-jira "<short summary>"           # create new ticket under epic SDK-5256
/ship-jira                             # ask: existing or new?
```

## What This Skill Does

### 1. Resolve the Jira ticket

- **If a ticket id is provided** (`SDK-XXXX`): fetch it via `mcp__claude_ai_Atlassian__getJiraIssue` to confirm it exists and is under the right epic.
- **If a summary is provided**: create a new Task under epic **SDK-5256 (Native Display v2)** via `mcp__claude_ai_Atlassian__createJiraIssue`. Required fields:
  - `cloudId`: `wizrocket.atlassian.net`
  - `projectKey`: `SDK`
  - `issueTypeName`: `Task`
  - `parent`: `SDK-5256`
  - `additional_fields`: `{"customfield_10441": [{"value": "Release Notes"}]}` ← **Documentation Required**, mandatory custom field; valid values are `"Release Notes"` or `"Dev Docs"`. Choose `Dev Docs` for internal API/dev-doc work, `Release Notes` for user-visible changes.
  - `description`: structured (Goal / Scope / Validation / Out of scope)

### 2. Branch

- Naming: `feat/SDK-XXXX-<kebab-slug>` (preferred) or `task/SDK-XXXX-<slug>` / `fix/SDK-XXXX-<slug>` for non-feature work.
- Created from the active release branch (default: `release/native-display-v1` — verify with `git branch --show-current` on a fresh checkout, or check the most recent merged PR's base).

```
git checkout -b feat/SDK-XXXX-tighten-sdk-visibility
```

### 3. Stage explicitly — never `git add -A`

Use the working tree to identify files actually touched by this change. **Skip files that pre-date the session** (check initial `git status` for the conversation). `git add <file1> <file2> …` — explicit list, no wildcards. Common false-positives: version-bump edits in sample `build.gradle.kts`, runtime artifacts, `.claude/scheduled_tasks.lock`.

### 4. Commit

Commit **subject** must lead with the ticket id:

```
SDK-XXXX: <imperative description> (Android | iOS | Android + iOS)
```

Body explains *why* (constraint, deadline, prior incident) and lists the *what* per platform. End with:

```
Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
```

Pass via heredoc to preserve formatting:

```bash
git commit -m "$(cat <<'EOF'
SDK-XXXX: <subject>

<body>

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

### 5. Push

```
git push -u origin feat/SDK-XXXX-<slug>
```

### 6. Pull request

Use `mcp__github__create_pull_request`:

- **owner**: `CleverTap`
- **repo**: `clevertap-native-ui-kit`
- **base**: `release/native-display-v1` (verify against most recent merged PR's `base.ref`)
- **head**: the feat branch
- **title**: `feat(SDK-XXXX): <description>` — **ticket id in parentheses, conventional-commit prefix**
- **body** must contain (sections in this order):
  1. `## Jira` — link to `SDK-XXXX` and parent epic `SDK-5256`
  2. `## Summary` — what changed and *why now*
  3. `## Changes` — per-platform tables (`### Android` / `### iOS`)
  4. `## Compatibility` — source-compat impact
  5. `## Test plan` — checkboxes; what passed locally vs. what reviewer must verify
  6. `## Out of scope` (optional)
  7. footer link refs `[SDK-XXXX]: https://wizrocket.atlassian.net/browse/SDK-XXXX` and `[SDK-5256]: …`
  8. `🤖 Generated with [Claude Code](https://claude.com/claude-code)`

## Examples

```bash
# Existing ticket
/ship-jira SDK-5780

# New ticket — skill creates it under SDK-5256 first
/ship-jira "Tighten SDK visibility/access modifiers for v1 release"

# Hotfix — use fix/ prefix
/ship-jira SDK-5781   # branch becomes fix/SDK-5781-… if commit type is fix
```

## Conventions captured from prior PRs

- Branch prefixes seen on this repo: `feat/`, `task/`, `fix/`. Match the commit-type prefix to the branch prefix.
- PR title leads with `feat(SDK-XXXX):` — recent style — or `SDK-XXXX:` (older). Prefer `feat(SDK-XXXX):` for new work.
- Jira parent epic for all Native Display v2 work: **SDK-5256**.
- Default PR base while v1 is in flight: `release/native-display-v1`. Re-verify if the release branch rotates.
- Jira project: `SDK` on `wizrocket.atlassian.net`.

## Required Jira custom field

Every Task creation under project `SDK` requires `customfield_10441` (**Documentation Required**) with a value of either `Release Notes` or `Dev Docs`. The skill MUST include this in `additional_fields` or the API call will fail with `"Documentation Required is required."`.

## Safety

- Never `git add -A` / `git add .` — always stage by explicit path.
- Never push to `main`, `release/*`, or any shared branch — only to the feat branch.
- Never `--force-push`.
- Never `--no-verify`.
- Never edit a Jira ticket that is `Done` / `Closed` to repurpose it — create a new one.
- If the working tree contains pre-existing unrelated changes, leave them alone — do not stage and do not stash without confirmation.

## Integration

- Wraps `/commit` (which enforces the commit-message format) and adds the branch + push + PR steps.
- Pairs with `/review` (run before opening PR) and `/build` + `/test` (run before committing).
