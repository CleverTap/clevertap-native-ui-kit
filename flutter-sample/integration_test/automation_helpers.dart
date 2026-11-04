// Shared helpers for the Flutter events/slots screenshot automation suite.
//
// This is the Flutter counterpart of:
//   android-sample/.../automation/AutomationTestHelpers.kt
//   ios-sample/.../automation/AutomationTestHelpers.swift
//
// All tests fire a fixed sequence of CleverTap events on a target screen and
// screenshot the canvas after each so a human can scrub through and compare the
// rendered native-display campaigns against Android and iOS.
//
// Screenshots are delivered to the host by `test_driver/integration_test.dart`
// (via the driver's onScreenshot hook), which writes them to
// ~/Desktop/nd-automation-output/flutter/ — mirroring where the Android Gradle
// task and iOS xcparse pull their PNGs.

import 'dart:io';

import 'package:clevertap_native_display_sample/automation/automation_signals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Canonical event list — byte-for-byte identical to Android's `EVENTS_TO_FIRE`
/// (AutomationTestHelpers.kt) and iOS's `EventsToFire` (AutomationTestHelpers
/// .swift). Order and casing matter: these are the exact dashboard-provisioned
/// campaign triggers for this sample app. The first ten (header1–5, footer1–5)
/// fire inline native-display campaigns; the rest map to slots.
const eventsToFire = <String>[
  'header1', 'header2', 'header3', 'header4', 'header5',
  'footer1', 'footer2', 'footer3', 'footer4', 'footer5',
  'nps', 'topi', 'kk', 'mm', 'ii', 'iip', 'ss', 'cptest',
  'hi', 'viewed', 'html2', 'home',
];

/// Brief post-handshake settle. Once the batch-counter handshake confirms this
/// event's units have landed and been `setState`'d (see [fireEventThroughScreen]
/// and `AutomationSignals.batchCount`), we still pump for a short window so the
/// campaign's images decode and paint into the surface before the screenshot.
/// This is no longer the primary gate — the handshake is — so it can be short.
const perEventWait = Duration(milliseconds: 1000);

/// Upper bound on how long to wait for a fired event's display-units batch to
/// come back from the server before giving up and screenshotting whatever is on
/// the canvas. The event-driven handshake normally resolves far sooner; this is
/// only a safety net so a dropped/empty server response can't hang the suite.
const batchHandshakeTimeout = Duration(seconds: 10);

/// Debounce window for the handshake. The CleverTap SDK can re-deliver the
/// previously-cached units after the canvas is cleared on send — bumping the
/// batch counter with STALE content before this event's real campaign lands.
/// Capturing on the first bump would therefore grab the previous event
/// (off-by-one). So after the counter advances we wait until it has been quiet
/// for this window — i.e. the delivery burst has settled — so the canvas shows
/// the LATEST (this event's) campaign.
const batchQuietPeriod = Duration(milliseconds: 1500);

/// Wait after tapping "Fetch Slot Data" before screenshotting, so the fired
/// campaigns have time to come back and populate the slots.
const fetchSlotWait = Duration(seconds: 4);

/// Real-time settle: `pumpAndSettle` can't be used around live network work
/// (the CleverTap SDK schedules frames/timers that never quiesce). Instead we
/// pump *repeatedly* across the whole wall-clock window so that (a) a campaign
/// arriving late in the window and (b) an async image decoding into the tree
/// both get painted into the surface before the screenshot is taken — a single
/// trailing pump would miss either.
Future<void> settle(WidgetTester tester, Duration total) async {
  const step = Duration(milliseconds: 150);
  await tester.pump();
  var elapsed = Duration.zero;
  while (elapsed < total) {
    await Future<void>.delayed(step);
    await tester.pump();
    elapsed += step;
  }
  // One more frame so an image that decoded on the final tick is painted.
  await tester.pump();
}

/// One-time preparation required before [IntegrationTestWidgetsFlutterBinding
/// .takeScreenshot] on Android (the Flutter surface must be rendered into an
/// image first). No-op on iOS, where the whole-screen grab works directly.
Future<void> prepareForScreenshots(
  IntegrationTestWidgetsFlutterBinding binding,
) async {
  if (Platform.isAndroid) {
    await binding.convertFlutterSurfaceToImage();
  }
}

/// Switch bottom-nav tab by its visible label ('Events', 'Slots', 'Browser',
/// 'More'). Preferring labels over indices keeps the tests readable and matches
/// the label-based navigation in the Android/iOS suites.
Future<void> switchToTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

/// Collapse the events log via the `event-log-toggle` so it doesn't cover the
/// Native Display canvas in screenshots. The log defaults to visible on every
/// launch, so call this once per Events-screen visit. No-op if already hidden
/// or the toggle isn't present.
Future<void> hideEventLog(WidgetTester tester) async {
  final toggle = find.byKey(const Key('event-log-toggle'));
  if (toggle.evaluate().isEmpty) return;
  // Only tap when the content is currently shown — tapping while hidden would
  // re-show it.
  if (find.byKey(const Key('event-log-content')).evaluate().isNotEmpty) {
    await tester.tap(toggle);
    await tester.pumpAndSettle();
  }
}

/// Type [eventName] into `ct-event-input`, tap `ct-send-event-btn`, then block on
/// an event-driven handshake until *this* event's display-units batch arrives —
/// guaranteeing the screenshot the caller takes reflects this event's server
/// response, not a stale previous one. Caller must already be on the Events tab.
/// Mirrors `fireEventThroughEventsScreen` on iOS and the type/tap loop on
/// Android (which use the equivalent batch-counter handshake).
///
/// Flow:
///  1. Snapshot the current batch counter.
///  2. Enter text, pump, tap Send. Firing clears the canvas (automation build),
///     so it falls back to the "Waiting…" state until the new batch lands.
///  3. Poll in real wall-clock time until the counter exceeds the snapshot OR
///     [batchHandshakeTimeout] elapses — the handshake is the primary gate.
///  4. Briefly settle so the batch's images decode and paint.
Future<void> fireEventThroughScreen(
  WidgetTester tester,
  String eventName,
) async {
  final before = AutomationSignals.batchCount.value;

  await tester.enterText(find.byKey(const Key('ct-event-input')), eventName);
  // Let the Send button flip to enabled (onChanged -> setState).
  await tester.pump();
  await tester.tap(find.byKey(const Key('ct-send-event-btn')));
  await tester.pump();

  // Primary gate: event-driven handshake WITH debounce. The counter can be
  // bumped by a re-delivery of the previous (stale) units after the canvas is
  // cleared, before this event's real campaign arrives — so we don't capture on
  // the first bump. We wait until the counter has (a) advanced past the snapshot
  // AND (b) then stayed unchanged for [batchQuietPeriod] (the delivery burst has
  // settled), so the canvas reflects the LATEST = this event's campaign. Bounded
  // by [batchHandshakeTimeout]; a no-campaign event never advances and simply
  // times out on the cleared/empty canvas (a truthful screenshot).
  const step = Duration(milliseconds: 150);
  final deadline = DateTime.now().add(batchHandshakeTimeout);
  var lastCount = before;
  DateTime? lastChange;
  while (DateTime.now().isBefore(deadline)) {
    final c = AutomationSignals.batchCount.value;
    if (c != lastCount) {
      lastCount = c;
      lastChange = DateTime.now();
    }
    if (c > before &&
        lastChange != null &&
        DateTime.now().difference(lastChange) >= batchQuietPeriod) {
      break;
    }
    await Future<void>.delayed(step);
    await tester.pump();
  }

  // Secondary settle: give the final batch's images time to decode and paint
  // before the caller screenshots.
  await settle(tester, perEventWait);
}
