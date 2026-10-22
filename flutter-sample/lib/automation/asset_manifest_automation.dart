// Automation-only asset manifest + cache warming.
//
// Gated entirely behind `--dart-define=ND_AUTOMATION=true`. In normal (human)
// runs every method here is a cheap no-op, so app behaviour is unchanged.
//
// Purpose: the screenshot automation ("nd-screenshot-compare" skill) currently
// has to run each capture TWICE — the first pass warms the image cache, the
// second is kept. This closes that gap:
//
//   1. COLLECT — as display units arrive (clevertap_integration_screen's
//      `_onUnitsLoaded`), we extract every http(s) asset URL via the SDK's
//      pure `AssetUrlCollector` and APPEND them (deduped, union across runs)
//      to an on-device manifest file.
//   2. WARM — at app startup we read the manifest and pre-download every URL
//      into the SAME cache `CachedNetworkImage` uses (flutter_cache_manager's
//      DefaultCacheManager), so the very first screenshot pass paints a warm
//      campaign.
//
// "Incremental" = the manifest is a union across runs: we read what's already
// there, add newly-seen URLs, and never drop previously-seen ones. So once an
// automation run has observed a campaign's assets, every later run warms them
// even before that campaign's unit arrives again.
//
// Manifest location: the app documents dir (sandbox-writable), file
// `nd-asset-urls.txt` (one URL per line). The host collects it by pulling that
// file off the device/sim; the absolute path is printed to the log on every
// append and warm so the capture scripts can locate it. (See
// `.claude/skills/nd-screenshot-compare` for where the host expects artifacts —
// mirror this file into ~/Desktop/nd-automation-output/ if desired.)

import 'dart:io';

import 'package:clevertap_native_display/clevertap_native_display.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

class AssetManifestAutomation {
  AssetManifestAutomation._();

  /// Set by the screenshot automation via `--dart-define=ND_AUTOMATION=true`.
  static const bool enabled = bool.fromEnvironment('ND_AUTOMATION');

  static const _manifestFileName = 'nd-asset-urls.txt';
  static const _tag = 'NDAutomation';

  static void _log(String msg) => debugPrint('[$_tag] $msg');

  /// Resolved manifest file, cached after first lookup.
  static File? _manifestFile;

  /// In-memory mirror of the on-disk manifest, so appends don't re-read the
  /// file every time a unit arrives.
  static final Set<String> _known = <String>{};
  static bool _loaded = false;

  static Future<File> _file() async {
    final cached = _manifestFile;
    if (cached != null) return cached;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_manifestFileName');
    _manifestFile = file;
    return file;
  }

  /// Load the existing manifest into memory (union seed). Safe to call repeatedly.
  static Future<void> _ensureLoaded() async {
    if (_loaded) return;
    try {
      final file = await _file();
      if (await file.exists()) {
        final lines = await file.readAsLines();
        _known.addAll(lines.map((l) => l.trim()).where((l) => l.isNotEmpty));
      }
    } catch (e) {
      _log('Could not read existing manifest: $e');
    }
    _loaded = true;
  }

  // ── Collection ────────────────────────────────────────────────────────────

  /// Extracts asset URLs from the just-received raw display units and appends
  /// any new ones (deduped) to the incremental manifest. No-op unless automation
  /// is enabled. [rawUnits] are the untouched platform-channel maps delivered to
  /// `_onUnitsLoaded` — we walk the raw JSON so all parse strategies are covered.
  static Future<void> recordUnits(List<dynamic> rawUnits) async {
    if (!enabled || rawUnits.isEmpty) return;
    try {
      await _ensureLoaded();
      final found = AssetUrlCollector.collectAll(rawUnits);
      final added = <String>[];
      for (final url in found) {
        if (_known.add(url)) added.add(url);
      }
      if (added.isEmpty) return;

      final file = await _file();
      // Append-only write preserves previously-seen URLs across runs.
      final sink = file.openWrite(mode: FileMode.append);
      for (final url in added) {
        sink.writeln(url);
      }
      await sink.flush();
      await sink.close();

      _log('Manifest +${added.length} new asset URL(s) '
          '(total ${_known.length}) -> ${file.path}');
    } catch (e) {
      _log('Failed to append to asset manifest: $e');
    }
  }

  // ── Warming ─────────────────────────────────────────────────────────────

  /// Reads the incremental manifest and pre-downloads every URL into the caches
  /// the renderer uses, so the first screenshot pass renders a warm campaign.
  ///
  /// Two cache paths are warmed to match [ImageElement]'s rendering:
  ///   * flutter_cache_manager (DefaultCacheManager) — backs CachedNetworkImage
  ///     for static images (the common case).
  ///   * precacheImage via NetworkImage — backs Image.network (gif / tile) and
  ///     also fills the in-memory ImageCache so decoded frames are ready.
  ///
  /// Videos (.mp4 etc.) are downloaded into the file cache too; they don't hit
  /// the image pipeline but warming them is harmless and helps VIDEO posters.
  /// No-op unless automation is enabled.
  static Future<void> warmCache(BuildContext? context) async {
    if (!enabled) return;
    try {
      await _ensureLoaded();
      final urls = _known.toList();
      if (urls.isEmpty) {
        _log('Asset manifest empty — nothing to warm yet. '
            'Run once to populate, subsequent runs will warm.');
        return;
      }
      _log('Warming cache for ${urls.length} manifest asset(s)…');

      final cacheManager = DefaultCacheManager();
      var ok = 0;
      await Future.wait(urls.map((url) async {
        try {
          // Fills flutter_cache_manager's disk cache (shared with
          // CachedNetworkImage).
          await cacheManager.downloadFile(url);
          ok++;
          // Also warm the in-memory ImageCache for Image.network / gif / tile.
          if (context != null && context.mounted && _isImage(url)) {
            await precacheImage(NetworkImage(url), context);
          }
        } catch (e) {
          // Offline / 404 / unreachable — skip, don't fail the run.
          _log('Warm failed for $url: $e');
        }
      }));

      _log('Cache warm complete: $ok/${urls.length} asset(s) ready.');
    } catch (e) {
      _log('Cache warming failed: $e');
    }
  }

  static bool _isImage(String url) {
    final lower = url.toLowerCase();
    const videoExts = ['.mp4', '.m3u8', '.webm', '.mov'];
    return !videoExts.any(lower.endsWith);
  }

  /// Exposes the absolute manifest path for logging / host collection.
  static Future<String> manifestPath() async => (await _file()).path;

  @visibleForTesting
  static void resetForTest() {
    _manifestFile = null;
    _known.clear();
    _loaded = false;
  }
}
