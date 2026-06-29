import { ResolvedStyles } from '../models/NativeDisplayConfig';
import { NativeDisplayNode, isContainer } from '../models/NativeDisplayNode';
import {
  Style,
  StyleClass,
  Theme,
  cascadingOnly,
  mergeStyles,
} from '../models/Style';

export class StyleResolver {
  private styleClassMap: Map<string, Style>;

  constructor(
    private theme: Theme,
    styleClasses: StyleClass[],
  ) {
    this.styleClassMap = new Map(styleClasses.map((sc) => [sc.name, sc.style]));
  }

  resolve(node: NativeDisplayNode): Style {
    // Resolution order: inline style > style class > theme default
    let resolved: Style = { ...this.theme.defaultStyle };

    if (node.styleClass) {
      const classStyle = this.styleClassMap.get(node.styleClass);
      if (classStyle) {
        resolved = mergeStyles(classStyle, resolved);
      }
    }

    if (node.style) {
      resolved = mergeStyles(node.style, resolved);
    }

    return resolved;
  }

  resolveWithColors(node: NativeDisplayNode): Style {
    const style = this.resolve(node);
    return {
      ...style,
      textColor: this.resolveColor(style.textColor),
      backgroundColor: this.resolveColor(style.backgroundColor),
      borderColor: this.resolveColor(style.borderColor),
      shadowColor: this.resolveColor(style.shadowColor),
    };
  }

  resolveAll(
    node: NativeDisplayNode,
    parentCascading: Style = {},
  ): ResolvedStyles {
    const result: ResolvedStyles = {};
    this._resolveAllInto(node, parentCascading, result);
    return result;
  }

  private _resolveAllInto(
    node: NativeDisplayNode,
    parentCascading: Style,
    result: ResolvedStyles,
  ): void {
    const ownStyle = this.resolveWithColors(node);
    const finalStyle = mergeStyles(ownStyle, parentCascading);
    result[node.id] = finalStyle;

    if (isContainer(node)) {
      const cascading = cascadingOnly(finalStyle);
      for (const child of node.children) {
        this._resolveAllInto(child, cascading, result);
      }
    }
  }

  private resolveColor(color: string | undefined): string | undefined {
    if (!color) return color;
    if (color.startsWith('#')) return color;
    return this.theme.colors[color] ?? color;
  }
}
