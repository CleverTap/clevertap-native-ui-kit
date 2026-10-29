/**
 * Runs work in a microtask so ongoing gestures/animations can finish before
 * heavy parsing starts. RN's version of the native SDKs' off-main-thread work.
 */
export function deferToIdle(work: () => void): void {
  Promise.resolve().then(work);
}

export function deferToIdleAsync<T>(work: () => T): Promise<T> {
  return Promise.resolve().then(work);
}
