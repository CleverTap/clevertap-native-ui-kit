import { NativeDisplayConfig } from '../models/NativeDisplayConfig';
import { NativeDisplayNode } from '../models/NativeDisplayNode';
import { parseDimension } from '../models/Layout';
import { parseTextDimension } from '../models/Style';

type Raw = Record<string, unknown>;

export function parseNativeDisplayConfig(raw: Raw): NativeDisplayConfig {
  return {
    version: (raw['version'] as string) ?? '1.0',
    theme: raw['theme'] ? parseTheme(raw['theme'] as Raw) : undefined,
    styleClasses: Array.isArray(raw['styleClasses'])
      ? (raw['styleClasses'] as Raw[]).map(parseStyleClass)
      : [],
    variables: (raw['variables'] as Record<string, unknown>) ?? {},
    root: raw['root'] ? parseNode(raw['root'] as Raw) : undefined,
  };
}

function parseTheme(raw: Raw) {
  return {
    id: (raw['id'] as string) ?? 'default',
    defaultStyle: raw['defaultStyle'] ? parseStyle(raw['defaultStyle'] as Raw) : {},
    colors: (raw['colors'] as Record<string, string>) ?? {},
  };
}

function parseStyleClass(raw: Raw) {
  return {
    name: (raw['name'] as string) ?? '',
    style: raw['style'] ? parseStyle(raw['style'] as Raw) : {},
  };
}

function parseNode(raw: Raw): NativeDisplayNode {
  const type = raw['type'] as string;

  if (type === 'container') {
    return {
      type: 'container',
      id: (raw['id'] as string) ?? '',
      containerType: (raw['containerType'] as string)?.toLowerCase() as import('../models/enums').ContainerType ?? 'vertical',
      children: Array.isArray(raw['children'])
        ? (raw['children'] as Raw[]).map(parseNode)
        : [],
      layout: raw['layout'] ? parseLayout(raw['layout'] as Raw) : undefined,
      style: raw['style'] ? parseStyle(raw['style'] as Raw) : undefined,
      styleClass: raw['styleClass'] as string | undefined,
      visible: raw['visible'] as string | undefined,
      actions: raw['actions'] ? raw['actions'] as Record<string, import('../models/Action').Action> : undefined,
      animation: raw['animation'] ? raw['animation'] as import('../models/Animation').Animation : undefined,
      galleryConfig: raw['galleryConfig'] ? raw['galleryConfig'] as import('../models/GalleryConfig').GalleryConfig : undefined,
      dividerConfig: raw['dividerConfig'] ? raw['dividerConfig'] as import('../models/NativeDisplayNode').DividerConfig : undefined,
    };
  }

  // element (default)
  return {
    type: 'element',
    id: (raw['id'] as string) ?? '',
    elementType: (raw['elementType'] as string)?.toLowerCase() as import('../models/enums').ElementType ?? 'text',
    bindings: (raw['bindings'] as Record<string, string>) ?? {},
    layout: raw['layout'] ? parseLayout(raw['layout'] as Raw) : undefined,
    style: raw['style'] ? parseStyle(raw['style'] as Raw) : undefined,
    styleClass: raw['styleClass'] as string | undefined,
    visible: raw['visible'] as string | undefined,
    actions: raw['actions'] ? raw['actions'] as Record<string, import('../models/Action').Action> : undefined,
    animation: raw['animation'] ? raw['animation'] as import('../models/Animation').Animation : undefined,
    dividerConfig: raw['dividerConfig'] ? raw['dividerConfig'] as import('../models/NativeDisplayNode').DividerConfig : undefined,
    imageConfig: raw['imageConfig'] ? raw['imageConfig'] as import('../models/NativeDisplayNode').ImageConfig : undefined,
    htmlConfig: raw['htmlConfig'] ? raw['htmlConfig'] as import('../models/NativeDisplayNode').HtmlConfig : undefined,
  };
}

function parseLayout(raw: Raw): import('../models/Layout').Layout {
  return {
    width: parseDimension(raw['width']),
    height: parseDimension(raw['height']),
    aspectRatio: raw['aspectRatio'] != null ? Number(raw['aspectRatio']) : undefined,
    offset: raw['offset'] ? raw['offset'] as import('../models/Layout').Offset : undefined,
    padding: raw['padding'] ? raw['padding'] as import('../models/Layout').Spacing : undefined,
    arrangement: raw['arrangement'] ? raw['arrangement'] as import('../models/Layout').ChildArrangement : undefined,
  };
}

function parseStyle(raw: Raw): import('../models/Style').Style {
  return {
    textColor: raw['textColor'] as string | undefined,
    fontSize: raw['fontSize'] != null ? parseTextDimension(raw['fontSize']) : undefined,
    fontFamily: raw['fontFamily'] as string | undefined,
    fontWeight: raw['fontWeight'] as import('../models/enums').FontWeight | undefined,
    fontStyle: raw['fontStyle'] as import('../models/enums').FontStyle | undefined,
    lineHeight: raw['lineHeight'] != null ? parseTextDimension(raw['lineHeight']) : undefined,
    letterSpacing: raw['letterSpacing'] != null ? Number(raw['letterSpacing']) : undefined,
    textDecoration: raw['textDecoration'] as import('../models/enums').TextDecoration | undefined,
    textAlign: raw['textAlign'] as string | undefined,
    maxLines: raw['maxLines'] != null ? Number(raw['maxLines']) : undefined,
    overflow: raw['overflow'] as import('../models/enums').TextOverflow | undefined,
    textShadow: raw['textShadow'] ? raw['textShadow'] as import('../models/Style').TextShadow : undefined,
    textGradient: raw['textGradient'] ? raw['textGradient'] as import('../models/Style').TextGradient : undefined,
    background: raw['background'] ? raw['background'] as import('../models/Background').Background : undefined,
    backgroundColor: raw['backgroundColor'] as string | undefined,
    borderRadius: raw['borderRadius'] != null ? parseDimension(raw['borderRadius']) : undefined,
    borderWidth: raw['borderWidth'] != null ? Number(raw['borderWidth']) : undefined,
    borderColor: raw['borderColor'] as string | undefined,
    shadowColor: raw['shadowColor'] as string | undefined,
    shadowRadius: raw['shadowRadius'] != null ? Number(raw['shadowRadius']) : undefined,
    shadowOffsetX: raw['shadowOffsetX'] != null ? Number(raw['shadowOffsetX']) : undefined,
    shadowOffsetY: raw['shadowOffsetY'] != null ? Number(raw['shadowOffsetY']) : undefined,
    opacity: raw['opacity'] != null ? Number(raw['opacity']) : undefined,
  };
}
