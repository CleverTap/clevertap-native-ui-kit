/**
 * Defer work to a microtask so any in-progress gestures or animations
 * finish before heavy parsing starts. This is the React Native equivalent of
 * the off-main-thread parsing used by the native SDKs.
 */
export function deferToIdle(work: () => void): void {
  Promise.resolve().then(work);
}

export function deferToIdleAsync<T>(work: () => T): Promise<T> {
  return Promise.resolve().then(work);
}
