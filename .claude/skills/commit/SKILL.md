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
   - Follows conventional commit format: `type: description`
   - Types: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`
   - Includes `Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>`
   - References affected platforms (Android/iOS) when relevant

3. **Creates Commit**
   - Stages relevant files if needed
   - Creates commit with proper message
   - Verifies commit success

## Commit Message Format

```
<type>: <description>

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

### Types
- **feat**: New feature (e.g., `feat: add GALLERY container support`)
- **fix**: Bug fix (e.g., `fix: correct style cascading for text properties`)
- **docs**: Documentation only (e.g., `docs: update CLAUDE.md with skills section`)
- **refactor**: Code restructuring (e.g., `refactor: extract style resolution logic`)
- **test**: Adding/fixing tests (e.g., `test: add unit tests for VariableEvaluator`)
- **chore**: Maintenance (e.g., `chore: update dependencies`)

## Examples

```bash
# Let skill auto-generate message
/commit

# Provide custom message
/commit -m "feat: add support for gradient backgrounds"
```

## Best Practices

1. **Stage files before committing**: Use `git add` to stage relevant files
2. **One logical change per commit**: Don't mix unrelated changes
3. **Reference issue numbers**: Include ticket IDs when relevant (e.g., `feat(SDK-5405): ...`)
4. **Cross-platform changes**: Mention both platforms if applicable (e.g., `feat: add iOS and Android support for...`)

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
