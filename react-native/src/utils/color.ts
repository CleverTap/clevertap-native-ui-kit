/**
 * Turns a hex color string into an rgb()/rgba() string React Native accepts.
 * Handles #RGB, #RGBA, #RRGGBB, #RRGGBBAA. Alpha is the last byte (RGBA order),
 * not the web ARGB order.
 *
 * Anything not starting with # is returned as-is, so 'red', 'transparent',
 * 'rgb(...)' etc. pass through unchanged.
 */
export function parseColor(color: string | undefined | null): string | undefined {
  if (!color) return undefined;
  if (!color.startsWith('#')) return color;

  const hex = color.slice(1);

  if (hex.length === 3) {
    const r = parseInt(hex[0]! + hex[0]!, 16);
    const g = parseInt(hex[1]! + hex[1]!, 16);
    const b = parseInt(hex[2]! + hex[2]!, 16);
    return `rgb(${r},${g},${b})`;
  }

  if (hex.length === 4) {
    const r = parseInt(hex[0]! + hex[0]!, 16);
    const g = parseInt(hex[1]! + hex[1]!, 16);
    const b = parseInt(hex[2]! + hex[2]!, 16);
    const a = parseInt(hex[3]! + hex[3]!, 16) / 255;
    return `rgba(${r},${g},${b},${a.toFixed(3)})`;
  }

  if (hex.length === 6) {
    const r = parseInt(hex.slice(0, 2), 16);
    const g = parseInt(hex.slice(2, 4), 16);
    const b = parseInt(hex.slice(4, 6), 16);
    return `rgb(${r},${g},${b})`;
  }

  if (hex.length === 8) {
    // #RRGGBBAA - alpha is the last byte (not web ARGB order)
    const r = parseInt(hex.slice(0, 2), 16);
    const g = parseInt(hex.slice(2, 4), 16);
    const b = parseInt(hex.slice(4, 6), 16);
    const a = parseInt(hex.slice(6, 8), 16) / 255;
    return `rgba(${r},${g},${b},${a.toFixed(3)})`;
  }

  return color;
}

export function parseColorWithFallback(color: string | undefined | null, fallback: string): string {
  return parseColor(color) ?? fallback;
}
