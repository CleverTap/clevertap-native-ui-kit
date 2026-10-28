// ─── Screenshot automation driver ──────────────────────────────────────────
//
// A deep-link-triggered mode that lets an external script drive the example app
// on a simulator/emulator where we can't tap or type. Opening the deep link
//
//     ndautomation://events?settle=<seconds>
//
// navigates to the CleverTap Integration (Events) screen and then fires the 22
// canonical CleverTap events in order, one every `settle` seconds, through the
// exact same path the "Send Event" button uses (CleverTap.recordEvent). Each
// event is written to the on-screen event log so a screenshot captures which
// event is active.
//
// The mode is gated strictly behind the deep link: nothing here runs unless the
// URL is opened, so normal app usage is completely unaffected.

import CleverTap from 'clevertap-react-native';

export const AUTOMATION_SCHEME = 'ndautomation';

/** Default seconds between events when the deep link omits `?settle=`. */
export const DEFAULT_SETTLE_SECONDS = 12;

// Order and casing matter — these mirror the canonical set used by the
// nd-screenshot-compare skill across Flutter, native and RN.
export const CANONICAL_EVENTS: readonly string[] = [
  'header1', 'header2', 'header3', 'header4', 'header5',
  'footer1', 'footer2', 'footer3', 'footer4', 'footer5',
  'nps', 'topi', 'kk', 'mm', 'ii', 'iip', 'ss', 'cptest',
  'hi', 'viewed', 'html2', 'home',
];

/**
 * Parsed form of an `ndautomation://events?settle=<seconds>` URL.
 * `null` when the URL is not an automation deep link we recognise.
 */
export interface AutomationRequest {
  settleSeconds: number;
}

/**
 * Returns an AutomationRequest when `url` is an `ndautomation://events` deep
 * link, otherwise null. Tolerant of a missing or malformed `settle` query.
 */
export function parseAutomationUrl(url: string | null | undefined): AutomationRequest | null {
  if (!url) return null;
  // Match the scheme + "events" host regardless of how the platform normalises
  // the authority (ndautomation://events or ndautomation:events).
  const prefix = `${AUTOMATION_SCHEME}://events`;
  const altPrefix = `${AUTOMATION_SCHEME}:events`;
  if (!url.startsWith(prefix) && !url.startsWith(altPrefix)) return null;

  let settleSeconds = DEFAULT_SETTLE_SECONDS;
  const q = url.indexOf('?');
  if (q >= 0) {
    const query = url.slice(q + 1);
    for (const pair of query.split('&')) {
      const [key, value] = pair.split('=');
      if (key === 'settle' && value !== undefined) {
        const parsed = Number(decodeURIComponent(value));
        if (Number.isFinite(parsed) && parsed > 0) {
          settleSeconds = parsed;
        }
      }
    }
  }
  return { settleSeconds };
}

// ─── Trigger bus ────────────────────────────────────────────────────────────
//
// App.tsx owns deep-link detection and navigation; the Events screen owns the
// fire loop (it already holds `appendLog` and the recordEvent path). This tiny
// bus decouples the two: App navigates to the Events tab and publishes the
// request; the screen subscribes and runs the sequence. A request published
// before the screen has subscribed (cold start) is held as `pending` so the
// screen picks it up on mount.

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

// ─── Fire loop ──────────────────────────────────────────────────────────────

const delay = (ms: number): Promise<void> =>
  new Promise((resolve) => setTimeout(resolve, ms));

// Module-level guard so a repeated deep link while a run is in flight cannot
// start a second overlapping sequence.
let running = false;

/**
 * Fires the 22 canonical events in order, one every `settleSeconds`, via
 * CleverTap.recordEvent — the same call `sendEvent()` makes. `onEvent` is
 * invoked for each fired event so the caller can write it to the on-screen log.
 * Fires exactly once per invocation and is a no-op if a run is already active.
 */
export async function runAutomation(
  request: AutomationRequest,
  onEvent: (name: string, index: number, total: number) => void,
): Promise<void> {
  if (running) return;
  running = true;
  try {
    const ms = request.settleSeconds * 1000;
    const total = CANONICAL_EVENTS.length;
    for (let i = 0; i < total; i++) {
      const name = CANONICAL_EVENTS[i];
      (CleverTap as unknown as { recordEvent: (n: string) => void }).recordEvent(name);
      onEvent(name, i, total);
      // Settle after each event (including the last) so the final screenshot
      // has the same dwell time as the rest.
      await delay(ms);
    }
  } finally {
    running = false;
  }
}
