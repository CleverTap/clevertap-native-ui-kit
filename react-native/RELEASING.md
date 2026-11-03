# Releasing @clevertap/native-display-sdk to npm

How to publish the React Native SDK to the public npm registry. Publishing is
manual - there is no CI job that does it (the only GitHub workflow, `docs.yml`,
just deploys the docs site to gh-pages).

Run every command from `react-native/` unless stated otherwise.

---

## What gets published

- **Package name:** `@clevertap/native-display-sdk` (a scoped package under the
  existing `@clevertap` npm org - the same org that publishes
  `@clevertap/clevertap-expo-plugin`).
- **Registry:** default public npm (`registry.npmjs.org`).
- **Access:** `package.json` has `"publishConfig": { "access": "public" }`, so
  a plain `npm publish` publishes publicly. You do NOT need to pass
  `--access public` on the command line.
- **Tarball contents:** controlled by the `files` allowlist in `package.json`
  (`dist`, `src`, `README.md`, `LICENSE`) and narrowed further by `.npmignore`
  (drops `example/`, tests, build config). The example apps and tests never
  ship.

> This package has not been published before. The first `npm publish` creates
> it. The `@clevertap` org already exists, so no org setup is needed - you only
> need to be a member with publish rights (see Prerequisites).

---

## Prerequisites (confirm once per machine)

1. You are logged in to npm as an account that belongs to the `@clevertap`
   org with publish rights: run `npm whoami`. If it errors, run `npm login`.
   To confirm membership, run `npm org ls clevertap` while logged in.
   TODO(verify): whether the org enforces 2FA (if it does, keep your
   authenticator ready - npm will prompt for an OTP at publish time).
2. Your working tree is clean and on the release branch, up to date with the
   remote. Check with `git status` and `git pull`.

---

## Step 1 - bump the version in BOTH places

The version lives in two files and they must match. The second one is a
hand-maintained copy, so `npm version` alone is not enough.

1. `react-native/package.json` - the `version` field.
2. `react-native/src/NativeDisplaySdkVersion.ts` - update two constants:
   - `NAME` - the semver string, e.g. `'1.2.3'`.
   - `CODE` - the integer `major * 10000 + minor * 100 + patch`.
     Examples: `1.0.0 -> 10000`, `1.2.3 -> 10203`, `2.0.1 -> 20001`.

`CODE` and `NAME` are stamped onto every Notification Viewed / Clicked event
(`nd_lib_v_name`, `nd_lib_v_code`), so a wrong value mislabels analytics on the
dashboard. Keep these in sync with the iOS and Android SDK versions when the
release is cross-platform, so the dashboard reads the same build number
everywhere.

> Prefer editing both files by hand over `npm version`. `npm version` only
> touches `package.json` and would leave `NativeDisplaySdkVersion.ts` stale. It
> also creates its own `v1.2.3` tag, which does not match this repo's
> per-platform tag convention (see Step 6).

---

## Step 2 - update the changelog

Add an entry for the new version to `CHANGELOG.md` at the repo root
(`clevertap-native-ui-kit/CHANGELOG.md`). Describe what changed since the last
release.

This is a multi-platform monorepo, so changelog headings name the platform
instead of using a bare version. Use a platform-scoped heading for the React
Native entry, e.g. `## [React Native 1.2.3] - Unreleased`, and add a matching
link reference at the bottom of the file that points to the release tag:

```
[React Native 1.2.3]: https://github.com/CleverTap/clevertap-native-ui-kit/releases/tag/react-native-v1.2.3
```

Set the heading to `Unreleased` while preparing, then replace it with the
release date (e.g. `## [React Native 1.2.3] - 2026-11-05`) when you tag.

---

## Step 3 - verify the build is clean

`prepublishOnly` runs `npm run build` automatically during `npm publish`, but
it does NOT run the tests. Run everything yourself first:

```
npm run build      # tsc --build, regenerates dist/
npm test           # jest
```

> There is a `lint` script (`eslint src`), but eslint is not installed and
> there is no eslint config, so it currently fails. It was removed from
> `prepublishOnly` so it cannot block a release. If eslint is set up later,
> add `npm run lint` back to the `prepublishOnly` chain.

Known test state as of this writing: the suite has 1 pre-existing unit-test
failure (`phase1.test.ts` "returns null when wzrk_id is missing", which expects
the old behavior before the `"0_0"` sentinel fallback) and 2 example-app test
suites that fail to load from `dist`. All three are test/example-only and are
excluded from the published tarball, so they do not block a release - but
confirm no NEW failures appeared from your changes before publishing.
TODO(verify): once the stale `phase1` test is updated, delete this note.

---

## Step 4 - dry run and inspect the tarball

See exactly what will ship before you ship it:

```
npm publish --dry-run
```

or build the tarball and list its contents:

```
npm pack
tar -tf clevertap-native-display-sdk-*.tgz
```

Check that `dist/` is present and current, `README.md` and `LICENSE` are
included, and that no `example/`, test, or config files leaked in. Delete the
`.tgz` afterward.

---

## Step 5 - publish

```
npm publish
```

Enter the OTP if npm prompts for 2FA. No `--access public` flag is needed -
`publishConfig.access` in `package.json` already sets it.

---

## Step 6 - tag the release in git

This is a multi-platform monorepo, so one bare semver tag can not identify a
single platform's release. The bare `X.Y.Z` tags are reserved for iOS: its
`Package.swift` sits at the repo root (Swift Package Manager resolves the
repo's bare semver tags) and the CocoaPods podspec sets
`:tag => "#{spec.version}"`. SPM ignores any tag that is not plain semver, so
iOS can not use a prefix.

Every other platform installs from its own registry (React Native from npm,
Flutter from pub.dev, Android from Maven), so its git tag is only a release
marker, not the install source. Those platforms tag with a platform prefix so
each release has its own tag and its own GitHub Release:

```
git commit -am "release react-native 1.2.3."   # version bump + changelog
git tag react-native-v1.2.3
git push && git push origin react-native-v1.2.3
```

(Adjust the version. Follow the repo's commit-message convention for the
commit text.)

> The npm package version and the git tag are separate namespaces. npm does
> not read git tags, so `@clevertap/native-display-sdk@1.2.3` publishes fine no
> matter what tags exist. The prefix only disambiguates the GitHub tag and
> Release.

> A `react-native-v*` tag does NOT trigger the docs-site workflow
> (`.github/workflows/docs.yml`). Its tag filter keeps the positive `*.*.*` but
> adds a negative `!*-v*`, so platform-prefixed tags are excluded. Only bare
> semver tags (the iOS/Android release tags) build and deploy the docs site.

---

## Step 7 - verify the publish

```
npm view @clevertap/native-display-sdk version
```

It should report the version you just published. Optionally install it in a
scratch project and import it to confirm the tarball resolves.

---

## Notes and gotchas

- **Two sources of version truth.** `package.json` and
  `NativeDisplaySdkVersion.ts` must agree. This is the easiest step to forget.
- **Public access is set in the manifest.** `publishConfig.access` is
  `"public"` in `package.json`, so a scoped publish goes out public. If that
  block is ever removed, you must pass `--access public` again or npm reverts
  to publishing privately.
- **`prepublishOnly` skips tests.** It only builds. Run `npm test` yourself.
- **Consumers get `dist/`.** `package.json` `main` is `dist/index.js`. The
  example apps in this repo bundle from `src/` via a Metro alias, so they do
  not exercise the published `dist/`. Treat the dry-run tarball as the real
  thing a customer installs.
- **No publish automation.** If a CI release job is added later, update this
  doc.
