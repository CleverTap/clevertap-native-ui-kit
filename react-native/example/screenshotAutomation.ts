// ─── Screenshot automation driver ──────────────────────────────────────────
//
// A deep-link-triggered mode that lets an external script drive the example app
// on a simulator/emulator where we can't tap or type. Two deep links:
//
//   PRIMARY — ndautomation://event?name=<eventName>
//     Navigate to the CleverTap Integration (Events) screen and fire exactly
//     that ONE event via CleverTap.recordEvent, logging it on-screen. The
//     capture script opens this 22 times (once per canonical event), sleeping
//     and screenshotting between each — so pacing is script-controlled with no
//     timer drift.
//
//   CONVENIENCE — ndautomation://events?settle=<seconds>
//     Fire all 22 canonical events in order, one every `settle` seconds
//     (default 12). Kept for manual/demo use; the capture script uses the
//     per-event form above.
//
// Both fire through the exact same path the "Send Event" button uses
// (CleverTap.recordEvent), and each fired event is written to the on-screen
// event log so a screenshot captures which event is active.
//
// The mode is gated strictly behind the deep link: nothing here runs unless one
// of these URLs is opened, so normal app usage is completely unaffected.

import CleverTap from 'clevertap-react-native';

export const AUTOMATION_SCHEME = 'ndautomation';

/** Default seconds between events for the `events` convenience link. */
export const DEFAULT_SETTLE_SECONDS = 12;

// Order and casing matter — these mirror the canonical set used by the
// nd-screenshot-compare skill across Flutter, native and RN.
export const CANONICAL_EVENTS: readonly string[] = [
  'header1', 'header2', 'header3', 'header4', 'header5',
  'footer1', 'footer2', 'footer3', 'footer4', 'footer5',
  'nps', 'topi', 'kk', 'mm', 'ii', 'iip', 'ss', 'cptest',
  'hi', 'viewed', 'html2', 'home',
];

/** True if `name` is one of the 22 canonical events (exact match). */
export function isCanonicalEvent(name: string): boolean {
  return CANONICAL_EVENTS.includes(name);
}

/**
 * A parsed automation deep link.
 *   - `single` → fire one named event (`ndautomation://event?name=...`)
 *   - `sequence` → fire all 22 with `settleSeconds` between
 *     (`ndautomation://events?settle=...`)
 */
export type AutomationRequest =
  | { kind: 'single'; name: string }
  | { kind: 'sequence'; settleSeconds: number };

/**
 * Returns an AutomationRequest when `url` is an automation deep link, otherwise
 * null. Recognises both `event` (single) and `events` (sequence) hosts and is
 * tolerant of how platforms normalise the authority (`://` vs `:`).
 */
export function parseAutomationUrl(url: string | null | undefined): AutomationRequest | null {
  if (!url) return null;

  // Strip the scheme + authority separator, leaving "<host>?<query>".
  const schemePrefix = `${AUTOMATION_SCHEME}://`;
  const altSchemePrefix = `${AUTOMATION_SCHEME}:`;
  let rest: string;
  if (url.startsWith(schemePrefix)) {
    rest = url.slice(schemePrefix.length);
  } else if (url.startsWith(altSchemePrefix)) {
    rest = url.slice(altSchemePrefix.length);
  } else {
    return null;
  }

  const q = rest.indexOf('?');
  const host = q >= 0 ? rest.slice(0, q) : rest;
  const query = q >= 0 ? rest.slice(q + 1) : '';
  const params = parseQuery(query);

  if (host === 'event') {
    const name = params.name?.trim();
    if (!name) return null; // no event named — nothing to fire
    return { kind: 'single', name };
  }

  if (host === 'events') {
    let settleSeconds = DEFAULT_SETTLE_SECONDS;
    const parsed = Number(params.settle);
    if (Number.isFinite(parsed) && parsed > 0) {
      settleSeconds = parsed;
    }
    return { kind: 'sequence', settleSeconds };
  }

  return null;
}

function parseQuery(query: string): Record<string, string> {
  const out: Record<string, string> = {};
  if (!query) return out;
  for (const pair of query.split('&')) {
    const eq = pair.indexOf('=');
    if (eq < 0) continue;
    const key = pair.slice(0, eq);
    const value = pair.slice(eq + 1);
    try {
      out[key] = decodeURIComponent(value);
    } catch {
      out[key] = value;
    }
  }
  return out;
}

// ─── Trigger bus ────────────────────────────────────────────────────────────
//
// App.tsx owns deep-link detection and navigation; the Events screen owns the
// firing (it already holds `appendLog` and the recordEvent path). This tiny bus
// decouples the two: App navigates to the Events tab and publishes the request;
// the screen subscribes and runs it. A request published before the screen has
// subscribed (cold start) is held as `pending` so the screen picks it up on
// mount.

type AutomationListener = (request: AutomationRequest) => void;

let listener: AutomationListener | null = null;
let pending: AutomationRequest | null = null;

/** Publish an automation request. Delivered now if the screen is listening,
 *  otherwise held until it subscribes (handles cold start). */
export function triggerAutomation(request: AutomationRequest): void {
  if (listener) {
    listener(request);
  } else {
    pending = request;
  }
}

/** Subscribe to automation requests. Immediately drains any pending request
 *  (published before mount). Returns an unsubscribe function. */
export function subscribeAutomation(fn: AutomationListener): () => void {
  listener = fn;
  if (pending) {
    const held = pending;
    pending = null;
    fn(held);
  }
  return () => {
    if (listener === fn) listener = null;
  };
}

// ─── Firing ─────────────────────────────────────────────────────────────────

const delay = (ms: number): Promise<void> =>
  new Promise((resolve) => setTimeout(resolve, ms));

/** Fire a single event through the same call `sendEvent()` makes. */
export function fireEvent(name: string): void {
  (CleverTap as unknown as { recordEvent: (n: string) => void }).recordEvent(name);
}

// Guards the sequence loop against a repeated `events` link overlapping itself.
// The single-event path needs no guard — each call fires once and returns.
let sequenceRunning = false;

/**
 * Fires the 22 canonical events in order, one every `settleSeconds`, via
 * CleverTap.recordEvent. `onEvent` is invoked for each fired event so the
 * caller can write it to the on-screen log. No-op if a sequence is already in
 * flight.
 */
export async function runSequence(
  settleSeconds: number,
  onEvent: (name: string, index: number, total: number) => void,
): Promise<void> {
  if (sequenceRunning) return;
  sequenceRunning = true;
  try {
    const ms = settleSeconds * 1000;
    const total = CANONICAL_EVENTS.length;
    for (let i = 0; i < total; i++) {
      const name = CANONICAL_EVENTS[i];
      fireEvent(name);
      onEvent(name, i, total);
      // Settle after each event (including the last) so the final screenshot
      // has the same dwell time as the rest.
      await delay(ms);
    }
  } finally {
    sequenceRunning = false;
  }
}
