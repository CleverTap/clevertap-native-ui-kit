/**
 * Generates a human-readable description of a NativeDisplayConfig JSON,
 * explaining what each element should look like and where it should be placed.
 * Used by TestConfigBrowserScreen to show a spec panel alongside the rendered output.
 */

// ─── Minimal local types (mirrors SDK models, avoids importing SDK internals) ──

interface Dim {
  value?: number;
  unit?: string;
  special?: string;
}

interface Spacing {
  all?: number;
  top?: number;
  right?: number;
  bottom?: number;
  left?: number;
  horizontal?: number;
  vertical?: number;
}

interface Arrangement {
  strategy?: string;
  spacing?: number;
  spacingUnit?: string;
}

interface Layout {
  width?: Dim;
  height?: Dim;
  padding?: Spacing;
  arrangement?: Arrangement;
  offset?: { x?: number; y?: number; unit?: string };
  aspectRatio?: number;
}

interface Style {
  backgroundColor?: string;
  background?: { type: string; colors?: string[]; color?: string };
  textColor?: string;
  fontSize?: number | { value: number; unit: string };
  fontWeight?: string;
  fontStyle?: string;
  lineHeight?: number | { value: number; unit: string };
  letterSpacing?: number;
  textAlign?: string;
  textDecoration?: string;
  maxLines?: number;
  borderRadius?: number | { value: number; unit: string };
  borderWidth?: number;
  borderColor?: string;
  shadowColor?: string;
  shadowRadius?: number;
  shadowOffsetX?: number;
  shadowOffsetY?: number;
  opacity?: number;
  overflow?: string;
}

interface Bindings {
  text?: string;
  url?: string;
  html?: string;
  autoPlay?: string | boolean;
  loop?: string | boolean;
  muted?: string | boolean;
  showControls?: string | boolean;
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyNode = Record<string, any>;

// ─── Dimension helpers ────────────────────────────────────────────────────────

function descDim(dim: Dim | undefined): string {
  if (!dim) return 'wrap_content';
  if (dim.special === 'wrap_content') return 'wrap_content';
  if (dim.special === 'match_parent') return 'match_parent';
  if (!dim.value && dim.value !== 0) return 'wrap_content';
  if (dim.value === -2) return 'wrap_content';
  if (dim.value === -1) return 'match_parent';
  const unit = dim.unit === 'percent' ? '%' : (dim.unit ?? 'dp');
  return `${dim.value}${unit}`;
}

function descLayout(layout: Layout | undefined): string {
  if (!layout) return '';
  const parts: string[] = [];

  const w = descDim(layout.width);
  const h = descDim(layout.height);
  parts.push(`${w} × ${h}`);

  if (layout.padding) {
    const p = layout.padding;
    if (p.all != null) {
      parts.push(`padding: ${p.all}dp`);
    } else {
      const sides: string[] = [];
      if (p.top != null) sides.push(`top: ${p.top}`);
      if (p.right != null) sides.push(`right: ${p.right}`);
      if (p.bottom != null) sides.push(`bottom: ${p.bottom}`);
      if (p.left != null) sides.push(`left: ${p.left}`);
      if (p.horizontal != null) sides.push(`h: ${p.horizontal}`);
      if (p.vertical != null) sides.push(`v: ${p.vertical}`);
      if (sides.length) parts.push(`padding: ${sides.join(', ')}dp`);
    }
  }

  if (layout.offset) {
    const o = layout.offset;
    const unit = o.unit ?? 'dp';
    parts.push(`offset: (${o.x ?? 0}, ${o.y ?? 0})${unit}`);
  }

  if (layout.aspectRatio != null) {
    parts.push(`aspectRatio: ${layout.aspectRatio}`);
  }

  return parts.join(', ');
}

function descArrangement(layout: Layout | undefined): string {
  const arr = layout?.arrangement;
  if (!arr) return '';
  const strategy = arr.strategy ?? 'spaced';
  if (strategy === 'spaced' && arr.spacing != null) {
    return `${strategy} ${arr.spacing}${arr.spacingUnit ?? 'dp'} gap`;
  }
  return strategy;
}

// ─── Style helpers ────────────────────────────────────────────────────────────

function descBackground(style: Style | undefined): string {
  if (!style) return '';
  const bg = style.background;
  if (bg) {
    switch (bg.type) {
      case 'solid': return `bg: solid ${bg.color ?? ''}`;
      case 'linear_gradient': return `bg: linear_gradient [${(bg.colors ?? []).join(', ')}]`;
      case 'radial_gradient': return `bg: radial_gradient [${(bg.colors ?? []).join(', ')}]`;
      case 'sweep_gradient': return `bg: sweep_gradient [${(bg.colors ?? []).join(', ')}]`;
      case 'animated_gradient': return `bg: animated_gradient [${(bg.colors ?? []).join(', ')}]`;
      case 'shimmer': return 'bg: shimmer (animated)';
      case 'pulse': return 'bg: pulse (animated)';
      case 'pattern': return `bg: pattern (${(bg as AnyNode).pattern_type ?? 'default'})`;
      case 'particles': return 'bg: particles (animated)';
      case 'image': return `bg: image ${(bg as AnyNode).url ?? ''}`;
      case 'layered': return `bg: layered (${((bg as AnyNode).layers ?? []).length} layers)`;
      default: return `bg: ${bg.type}`;
    }
  }
  if (style.backgroundColor) return `bg: solid ${style.backgroundColor}`;
  return '';
}

function descTextStyle(style: Style | undefined): string {
  if (!style) return '';
  const parts: string[] = [];
  if (style.textColor) parts.push(`color: ${style.textColor}`);
  if (style.fontSize != null) {
    const fs = typeof style.fontSize === 'object'
      ? `${style.fontSize.value}% of root`
      : `${style.fontSize}sp`;
    parts.push(`size: ${fs}`);
  }
  if (style.fontWeight) parts.push(`weight: ${style.fontWeight}`);
  if (style.fontStyle) parts.push(`style: ${style.fontStyle}`);
  if (style.textAlign) parts.push(`align: ${style.textAlign}`);
  if (style.textDecoration) parts.push(`decoration: ${style.textDecoration}`);
  if (style.maxLines != null) parts.push(`maxLines: ${style.maxLines}`);
  if (style.letterSpacing != null) parts.push(`letterSpacing: ${style.letterSpacing}`);
  return parts.join(', ');
}

function descVisualStyle(style: Style | undefined): string {
  if (!style) return '';
  const parts: string[] = [];
  if (style.borderRadius != null) {
    const br = typeof style.borderRadius === 'object'
      ? `${style.borderRadius.value}% of root height`
      : `${style.borderRadius}dp`;
    parts.push(`radius: ${br}`);
  }
  if (style.borderWidth != null) parts.push(`border: ${style.borderWidth}dp ${style.borderColor ?? ''}`);
  if (style.shadowColor) {
    parts.push(`shadow: ${style.shadowColor} offset(${style.shadowOffsetX ?? 0},${style.shadowOffsetY ?? 0}) blur${style.shadowRadius ?? 0}`);
  }
  if (style.opacity != null) parts.push(`opacity: ${style.opacity}`);
  return parts.join(', ');
}

// ─── Node describer ───────────────────────────────────────────────────────────

function descNode(node: AnyNode, indent: number): string {
  const pad = '  '.repeat(indent);
  const lines: string[] = [];

  if (node.type === 'container') {
    const cType = (node.containerType as string ?? 'unknown').toUpperCase();
    const layout = descLayout(node.layout as Layout);
    const arr = descArrangement(node.layout as Layout);
    const bg = descBackground(node.style as Style);
    const visual = descVisualStyle(node.style as Style);

    let header = `${pad}[${cType}] ${layout}`;
    if (arr) header += ` | ${arr}`;
    lines.push(header);
    if (bg) lines.push(`${pad}  ${bg}`);
    if (visual) lines.push(`${pad}  ${visual}`);

    const children: AnyNode[] = node.children ?? [];
    children.forEach((child: AnyNode, i: number) => {
      lines.push(`${pad}  Child ${i + 1}:`);
      lines.push(descNode(child, indent + 2));
    });

  } else if (node.type === 'element') {
    const eType = (node.elementType as string ?? 'unknown').toUpperCase();
    const layout = descLayout(node.layout as Layout);
    const style = node.style as Style | undefined;
    const bindings = node.bindings as Bindings | undefined;
    const bg = descBackground(style);
    const visual = descVisualStyle(style);

    switch (node.elementType) {
      case 'text': {
        const text = bindings?.text ?? '(no text)';
        const textStyle = descTextStyle(style);
        lines.push(`${pad}[TEXT] "${text}" | ${layout}`);
        if (textStyle) lines.push(`${pad}  ${textStyle}`);
        if (bg) lines.push(`${pad}  ${bg}`);
        if (visual) lines.push(`${pad}  ${visual}`);
        break;
      }
      case 'image': {
        const url = bindings?.url ?? '(no url)';
        const fit = (node.imageConfig as AnyNode)?.fit ?? 'crop (default)';
        lines.push(`${pad}[IMAGE] ${layout}`);
        lines.push(`${pad}  url: ${url}`);
        lines.push(`${pad}  fit: ${fit}`);
        if (bg) lines.push(`${pad}  ${bg}`);
        if (visual) lines.push(`${pad}  ${visual}`);
        break;
      }
      case 'button': {
        const text = bindings?.text ?? '(no label)';
        const textStyle = descTextStyle(style);
        lines.push(`${pad}[BUTTON] "${text}" | ${layout}`);
        if (bg) lines.push(`${pad}  ${bg}`);
        if (textStyle) lines.push(`${pad}  ${textStyle}`);
        if (visual) lines.push(`${pad}  ${visual}`);
        break;
      }
      case 'video': {
        const url = bindings?.url ?? '(no url)';
        const flags = [
          bindings?.autoPlay != null && `autoPlay: ${bindings.autoPlay}`,
          bindings?.loop != null && `loop: ${bindings.loop}`,
          bindings?.muted != null && `muted: ${bindings.muted}`,
          bindings?.showControls != null && `controls: ${bindings.showControls}`,
        ].filter(Boolean).join(', ');
        lines.push(`${pad}[VIDEO] ${layout}`);
        lines.push(`${pad}  url: ${url}`);
        if (flags) lines.push(`${pad}  ${flags}`);
        break;
      }
      case 'html': {
        const src = bindings?.html ? '(inline HTML)' : (bindings?.url ?? '(no source)');
        lines.push(`${pad}[HTML] ${layout}`);
        lines.push(`${pad}  source: ${src}`);
        break;
      }
      case 'spacer': {
        lines.push(`${pad}[SPACER] ${layout}`);
        break;
      }
      case 'divider': {
        const thickness = (node.dividerConfig as AnyNode)?.thickness ?? 1;
        const color = (node.dividerConfig as AnyNode)?.color ?? style?.borderColor ?? '#E0E0E0';
        lines.push(`${pad}[DIVIDER] ${thickness}dp thick, color: ${color} | ${layout}`);
        break;
      }
      default:
        lines.push(`${pad}[${eType}] ${layout}`);
    }
  }

  return lines.join('\n');
}

// ─── Public API ───────────────────────────────────────────────────────────────

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function describeConfig(config: Record<string, any>): string {
  const lines: string[] = [];

  // Theme summary
  const theme = config.theme as AnyNode | undefined;
  if (theme?.defaultStyle) {
    const ds = theme.defaultStyle as Style;
    const parts: string[] = [];
    if (ds.textColor) parts.push(`textColor: ${ds.textColor}`);
    if (ds.fontSize) parts.push(`fontSize: ${ds.fontSize}`);
    if (ds.fontWeight) parts.push(`fontWeight: ${ds.fontWeight}`);
    lines.push(`Theme: ${parts.join(', ')}`);
  }

  // Style classes summary
  const classes = config.styleClasses as AnyNode[] | undefined;
  if (classes && classes.length > 0) {
    const names = classes.map((c: AnyNode) => c.id ?? c.name ?? '?').join(', ');
    lines.push(`Style classes: ${names}`);
  }

  // Variables summary
  const vars = config.variables as Record<string, unknown> | undefined;
  if (vars && Object.keys(vars).length > 0) {
    const entries = Object.entries(vars).map(([k, v]) => `${k}: ${v}`).join(', ');
    lines.push(`Variables: ${entries}`);
  }

  if (lines.length > 0) lines.push('');

  // Root node
  if (config.root) {
    lines.push('Layout tree:');
    lines.push(descNode(config.root as AnyNode, 0));
  }

  return lines.join('\n');
}
