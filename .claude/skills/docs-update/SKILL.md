---
name: docs-update
description: Update the docs site (website/docs/) for an SDK change — new component, new field, renamed symbol, or behaviour change.
user-invocable: true
disable-model-invocation: false
---

# Docs Update Skill

Run after a code change that affects the public SDK surface. Walks through the markdown files that need updating so nothing drifts.

The skill is **not** for API reference changes — those flow automatically from KDoc / `///` comments via Dokka and DocC. Use this skill only for changes to the **narrative documentation** in `website/docs/`.

## Usage

```bash
/docs-update added STACK container
/docs-update added borderStyle field to BOX style block
/docs-update renamed ContainerType.GALLERY to CAROUSEL
/docs-update changed percent formula from /100 to /1000
/docs-update                     # interactive — asks what changed
```

## When to use

| Change in source | Run /docs-update? |
|------------------|-------------------|
| Added a public class with KDoc / `///` comments | No — Dokka/DocC pick it up automatically |
| Added a new container type / element type | **Yes** — needs a new page + sidebar entry |
| Added a new field on an existing component | **Yes** — needs schema + component page update |
| Renamed a public symbol | **Yes** — `<ApiLink>` references in markdown will dangle |
| Changed a default value or parsing rule | **Yes** — narrative claims become stale |
| Pure refactor with no public surface change | No |
| Internal-only change | No |

## What this skill does

1. **Classify the change** from the description (or by asking):
   - **New component** → new page + sidebar + intro + JSON schema + changelog
   - **New field on existing component** → component page + JSON schema + changelog
   - **Renamed symbol** → grep `website/docs/` for old name, replace, fix `<ApiLink>`s
   - **Behaviour change** → identify pages that describe the old behaviour, update them
2. **Read the canonical template** — `website/docs/components/containers/box.md` is the model component page; `website/docs/components/elements/text.md` is the model element page. New pages follow the same section order: Overview · Visual model · Features · JSON schema · Layout/style · Platform parity · Examples · Pitfalls · See also.
3. **Draft / edit the markdown**:
   - Component or element page (new or updated section).
   - `website/docs/json-reference/v1.0.0-schema.md` — extend the type definitions.
   - `website/docs/intro.md` — keep the "What's documented" lists in sync.
   - `website/sidebars.ts` — add the new entry.
   - `website/docs/changelog.md` and root `CHANGELOG.md` — add an entry under the current unreleased version.
4. **Re-snapshot if a release is imminent**:
   ```
   rm -rf website/versioned_docs website/versioned_sidebars website/versions.json
   cd website && npx docusaurus docs:version <next-version>
   ```
   Skip this for in-progress doc updates — only run when cutting a release.
5. **Verify**:
   ```
   cd website && npm run build
   ```
   Build must pass clean (no broken links). Hot-reload the dev server if running.

## Files this skill touches

| File | When |
|------|------|
| `website/docs/components/containers/<name>.md` | New container |
| `website/docs/components/elements/<name>.md` | New element |
| `website/docs/dimensions/<unit>.md` | New unit |
| `website/docs/concepts/<topic>.md` | New cross-cutting concept |
| `website/docs/json-reference/v1.0.0-schema.md` | Any field-level change |
| `website/docs/intro.md` | New surface or removed feature |
| `website/docs/changelog.md` | Every user-visible change |
| `CHANGELOG.md` (repo root) | Same |
| `website/sidebars.ts` | New page |

## What it does NOT touch

- `android/sdk/src/main/**` and `ios/Sources/**` — KDoc / `///` lives in source. Edit it there directly; it'll regenerate on next CI build.
- `versioned_docs/version-X.Y.Z/` — frozen snapshots. Never edit by hand. Use `docusaurus docs:version` to re-snapshot.
- The CI workflow `.github/workflows/docs.yml` — no change needed for content updates.

## Per-component template (for new component pages)

```markdown
---
title: <NAME> <kind>
sidebar_label: <NAME>
description: <one-line summary>
---

# <NAME>

<one-paragraph overview — what is it, when do I use it>

## Visual model

<ASCII diagram or screenshot reference>

## Features

- <bulleted feature list>

## JSON schema

<code block with full schema>

| Field | Required | Notes |
|-------|----------|-------|
| ... | ... | ... |

## Layout behaviour

<sizing rules, child positioning, what's unique to this component>

## Style support

<which style props apply, which cascade>

## Platform parity

| Platform | Primitive | Source |
|----------|-----------|--------|
| Android | <Compose primitive> | <file:line> |
| iOS | <SwiftUI primitive> | <file:line> |

## Examples

<2–4 progressive examples, lifted from test-configs/ when possible>

## Common pitfalls

<things users hit; what surprises them>

## See also

<cross-links>
```

## Per-field-addition template (existing component)

For "added `borderStyle` to BOX style block":

1. Append to the JSON schema table on the component page.
2. Append the type definition in `json-reference/v1.0.0-schema.md` under the matching `Style` block.
3. Add an "Examples" entry showing the new field in use.
4. Add a changelog entry under "Added".
5. If the new field has a non-obvious default or platform difference, add a paragraph under "Platform parity" or "Common pitfalls".

## Related skills

- `/build` — build the SDK after a source change
- `/test` — run tests
- `/commit` — commit the doc updates after they're verified
- `/docs-audit` — run before a release to catch anything this skill missed
