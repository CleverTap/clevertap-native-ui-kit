---
name: docs-audit
description: Pre-release scan for docs drift — finds undocumented public symbols, dangling references, and missing changelog entries.
user-invocable: true
disable-model-invocation: false
---

# Docs Audit Skill

Runs a punch-list scan across the SDK source tree and `website/docs/` to find places where the docs and the code disagree. Designed to be run **before cutting a release** so nothing ships undocumented.

## Usage

```bash
/docs-audit                       # audit since the last v*.*.* tag
/docs-audit --since v1.0.0        # audit since a specific tag
/docs-audit --since 2026-04-01    # audit since a date
/docs-audit --strict              # treat warnings as errors (CI mode)
```

## What this skill checks

### 1. New public symbols without doc coverage

```bash
git log --since=<last-tag> --diff-filter=A --name-only -- 'android/sdk/src/main/**' 'ios/Sources/**'
```

For each file added or substantially modified:
- Look at every `public` Kotlin / Swift symbol added.
- Grep `website/docs/` for the symbol name.
- If absent → **flag**: needs a doc page or a mention in an existing page.

Special focus:
- **New `containerType` enum case** (e.g. someone added `STACK` to `ContainerType`) → must have a `website/docs/components/containers/<name>.md` page.
- **New `elementType` enum case** → must have a `website/docs/components/elements/<name>.md` page.
- **New `DimensionUnit` case** → must have a `website/docs/dimensions/<name>.md` page.
- **New `ArrangementStrategy`, `AnimationType`, `Easing`, `GalleryMode`, `SnapBehavior`, `ImageFit`** case → must be listed in the relevant concept / component page.

### 2. Dangling `<ApiLink>` references

The `<ApiLink platform="..." path="...">` MDX component points at Dokka / DocC pages. If a public symbol was renamed or removed, the link 404s.

```bash
grep -rE '<ApiLink[^>]*path="[^"]+"' website/docs/
```

For each `path="..."`:
- If platform is `android` → check it resolves under `android/sdk/build/dokka/html/` after a fresh `./gradlew :sdk:dokkaHtml`.
- If platform is `ios` → check the corresponding DocC topic exists.

### 3. Markdown references to source paths or symbol names

The narrative pages cite source paths and symbol names (e.g. `NativeDisplayRenderer.kt:282–298`, `RenderContainer`, `applySizing`). If those moved or were renamed, the docs lie.

For each file under `website/docs/`:
- Extract every backtick-quoted identifier and every `<file>.kt:<lines>` / `<file>.swift:<lines>` reference.
- Confirm the file exists and the identifier is still in source via `Grep`.
- Line numbers don't have to match exactly (they drift) — flag only when the file or symbol no longer exists.

### 4. JSON schema completeness

`website/docs/json-reference/v1.0.0-schema.md` is hand-maintained. Diff what it documents against the actual `kotlinx.serialization` / `Codable` types.

For each `@Serializable` class / `Codable` struct in `models/`:
- Pull the public field names.
- Confirm the schema markdown lists them.
- Flag missing ones.

### 5. Sidebar coverage

`website/sidebars.ts` lists every page exposed in nav. Cross-reference:
- Every `website/docs/**/*.md` file → must appear in `sidebars.ts` (or be intentionally excluded with a comment).
- Every `sidebars.ts` entry → must resolve to a real `.md` file.

### 6. Changelog freshness

For each commit since the last `v*.*.*` tag:
- If commit message starts with `feat`, `fix`, or `breaking` → flag if not represented in `CHANGELOG.md` under the unreleased section.
- If commit touches `android/sdk/src/main/` or `ios/Sources/` and modifies a public symbol → must have a changelog line.

### 7. Sample-app code-block sync

Getting-started pages (`getting-started/android-compose.md`, etc.) embed code snippets. They should match what the corresponding sample app actually does.

For each fenced code block in those pages:
- Extract the imports and main API calls.
- Grep the corresponding sample app source for the same call patterns.
- Flag if the sample uses a different signature or a new method that the docs missed.

## Output format

```
📋 Docs Audit (since v1.0.0 — 47 commits, 12 files changed)
=========================================================

🔴 NEEDS DOC PAGE (1)
  - ContainerType.STACK added in android/sdk/.../models/Enums.kt
    → Create website/docs/components/containers/stack.md
    → Add to sidebars.ts under Components → Containers
    → Mention in website/docs/intro.md "What's documented"

🟠 SCHEMA OUT OF SYNC (2)
  - Style.borderStyle field added in models/Style.kt:45
    → Missing from website/docs/json-reference/v1.0.0-schema.md (Style block)
    → Missing from website/docs/components/containers/box.md (style table)
  - GalleryConfig.transitionDuration field added in models/GalleryConfig.kt:31
    → Missing from website/docs/components/containers/gallery.md (galleryConfig table)

🟡 DANGLING REFERENCES (3)
  - website/docs/components/containers/box.md:142
    cites `RenderNode` at NativeDisplayRenderer.kt:282–298
    → File still exists, symbol still exists, line numbers drifted (now :310–326).
    → Acceptable. (line numbers always drift; flagged for visibility only)
  - website/docs/components/elements/image.md:89
    cites `Coil ImageLoader` — symbol no longer present in android/sdk/
    → Coil dependency was replaced; update the platform parity section.
  - website/docs/concepts/animations.md:52
    `<ApiLink platform="android" path="ui-kit/.../animation-modifier">` → 404 in Dokka output.

🟡 CHANGELOG (4)
  Commits since v1.0.0 not represented in CHANGELOG.md:
  - feat(SDK-5800): add STACK container       (commit abc1234)
  - feat(SDK-5801): borderStyle on Style      (commit def5678)
  - fix(SDK-5802): percent on wrap_content   (commit ghi9012)
  - feat(SDK-5803): GALLERY transitionDuration (commit jkl3456)

🟢 SIDEBAR (clean)
🟢 SAMPLE-APP SYNC (clean)

---

OVERALL: 1 critical (missing page), 2 high (schema gaps), 3 medium (dangling refs), 4 medium (changelog).
RECOMMENDATION: Fix critical and high before tagging the release.
```

## Workflow

```bash
# Before cutting a release
/docs-audit

# Address each flagged item with /docs-update
/docs-update added STACK container
/docs-update added borderStyle field to BOX style block
/docs-update added transitionDuration to galleryConfig

# Manually update changelog for any items the skill flagged
# Re-run audit
/docs-audit

# When clean, snapshot the new version
cd website && npx docusaurus docs:version 1.1.0

# Commit, tag, push — CI deploys the docs
git tag v1.1.0 && git push origin v1.1.0
```

## What this skill does NOT do

- **Doesn't fix anything**. It only reports. Pair with `/docs-update` to apply fixes.
- **Doesn't validate API ref content**. Dokka and DocC are trusted to be correct because they read source comments directly.
- **Doesn't run integration tests**. Use `/test` for that.
- **Doesn't deploy**. CI handles that on tag push.

## Related skills

- `/docs-update <feature>` — fix individual items the audit flags
- `/build` — verify SDK still builds before tagging
- `/test` — run tests
- `/commit` — commit doc updates
- `/review` — review the doc PR before merging

## Tips for keeping the audit clean

- Run `/docs-audit` after every PR that touches `android/sdk/src/main/` or `ios/Sources/`, not just before releases.
- Treat a dangling `<ApiLink>` the same as a broken test — fix it before merging.
- Whenever you add a new `containerType` / `elementType` case, also add the docs page in the same PR. Skip-doc PRs are how drift compounds.
