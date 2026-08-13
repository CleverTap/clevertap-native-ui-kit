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

/// Per-event settle wait. The Native Display server is asynchronous — this is
/// the floor below which the unit hasn't rendered by screenshot time. Matches
/// the 1.5s used by Android and iOS. Bump if flaky.
const perEventWait = Duration(milliseconds: 1500);

/// Wait after tapping "Fetch Slot Data" before screenshotting, so the fired
/// campaigns have time to come back and populate the slots. Matches iOS's 3s.
const fetchSlotWait = Duration(seconds: 3);

/// Real-time settle: `pumpAndSettle` can't be used around live network work
/// (the CleverTap SDK schedules frames/timers that never quiesce), so we pump
/// once, wait wall-clock, and pump again to flush the resulting rebuild.
Future<void> settle(WidgetTester tester, Duration d) async {
  await tester.pump();
  await Future<void>.delayed(d);
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

/// Type [eventName] into `ct-event-input` and tap `ct-send-event-btn`, then wait
/// [perEventWait] for the server response to land. Caller must already be on the
/// Events tab. Mirrors `fireEventThroughEventsScreen` on iOS and the type/tap
/// loop on Android.
Future<void> fireEventThroughScreen(
  WidgetTester tester,
  String eventName,
) async {
  await tester.enterText(find.byKey(const Key('ct-event-input')), eventName);
  // Let the Send button flip to enabled (onChanged -> setState).
  await tester.pump();
  await tester.tap(find.byKey(const Key('ct-send-event-btn')));
  await settle(tester, perEventWait);
}
