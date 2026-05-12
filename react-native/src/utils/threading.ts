/**
 * Defer work to a microtask so in-flight JS gestures/animations
 * finish before heavy parsing begins. This is the RN equivalent of
 * "off-main-thread" parsing used by the native SDKs.
 */
export function deferToIdle(work: () => void): void {
  Promise.resolve().then(work);
}

export function deferToIdleAsync<T>(work: () => T): Promise<T> {
  return Promise.resolve().then(work);
}
