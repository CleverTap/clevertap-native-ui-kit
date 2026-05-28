---
name: commit
description: Create git commit following project conventions
user-invocable: true
disable-model-invocation: false
---

# Commit Skill

Creates a git commit following the Native Display System project conventions.

## Usage

Invoke with `/commit` or `/commit -m "custom message"`

## What This Skill Does

1. **Analyzes Changes**
   - Runs `git status` to see staged/unstaged files
   - Runs `git diff` to understand the changes
   - Reviews recent commits for style consistency

2. **Generates Commit Message**
   - Subject **must** lead with a Jira ticket id: `SDK-XXXX: …` or `<type>(SDK-XXXX): …`
   - Types: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`
   - Includes `Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>`
   - References affected platforms (Android/iOS) when relevant
   - If no ticket exists, run `/ship-jira "<summary>"` first to create one under epic `SDK-5256`

3. **Creates Commit**
   - Stages relevant files if needed
   - Creates commit with proper message
   - Verifies commit success

## Commit Message Format

**Every commit on this repo must reference a Jira ticket.** The subject leads with the ticket id, in one of two equivalent forms:

```
SDK-XXXX: <description>
```
or
```
<type>(SDK-XXXX): <description>
```

The body explains *why* (constraint, prior incident, deadline) and the *what* per platform when relevant. End with the trailer:

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

### Types
- **feat**: New feature (e.g., `feat(SDK-5405): add GALLERY container support`)
- **fix**: Bug fix (e.g., `fix(SDK-5612): correct style cascading for text properties`)
- **docs**: Documentation only (e.g., `docs(SDK-5555): update CLAUDE.md with skills section`)
- **refactor**: Code restructuring (e.g., `refactor(SDK-5780): tighten SDK visibility for v1`)
- **test**: Adding/fixing tests (e.g., `test(SDK-5444): add unit tests for VariableEvaluator`)
- **chore**: Maintenance (e.g., `chore(SDK-5500): update dependencies`)

If no ticket exists for the change, run `/ship-jira "<summary>"` first — it creates a Task under epic `SDK-5256` and returns the new ticket id.

## Examples

```bash
# Let skill auto-generate message (requires SDK-XXXX ticket id from context or branch name)
/commit

# Provide custom message — ticket id is required in the subject
/commit -m "feat(SDK-5407): add support for gradient backgrounds"
```

## Best Practices

1. **Stage files before committing**: Use `git add` to stage relevant files
2. **One logical change per commit**: Don't mix unrelated changes
3. **Reference Jira tickets — required**: every commit subject must contain `SDK-XXXX`. If no ticket exists, run `/ship-jira "<summary>"` first to create one under epic `SDK-5256`
4. **Cross-platform changes**: Mention both platforms if applicable (e.g., `feat(SDK-XXXX): add iOS and Android support for...`)
5. **Stage explicitly — never `git add -A`**: stage by explicit path so unrelated working-tree changes (version bumps, lock files, runtime artifacts) don't slip in
6. **Branch name should also carry the ticket**: pair this skill with `/ship-jira`, which creates `feat/SDK-XXXX-<slug>` branches that match the commit subject

## What Gets Analyzed

- Git status (staged and unstaged files)
- Git diff (actual changes)
- Recent commit history (last 5 commits for style)
- File paths to determine affected components

## Safety

- Never commits files with secrets (.env, credentials, etc.)
- Warns if committing large files
- Confirms before committing if changes affect multiple platforms
- Never uses `--no-verify` flag (runs pre-commit hooks)

## Integration with Project

- Follows conventions from `CLAUDE.md`
- Respects `.gitignore` rules
- Compatible with project's git workflow
- Works with both Android and iOS changes
- Pairs with `/ship-jira` for the full workflow (Jira ticket → branch → commit → push → PR)
