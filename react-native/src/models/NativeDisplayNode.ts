import { Action, ActionTrigger } from './Action';
import { Animation } from './Animation';
import { GalleryConfig } from './GalleryConfig';
import { Layout } from './Layout';
import { Style } from './Style';
import { ContainerType, ElementType, ImageFit, Orientation } from './enums';

export interface DividerConfig {
  orientation: Orientation;
  thickness: number;
  color: string;
}

export interface ImageConfig {
  fit?: ImageFit;
  animated?: boolean | null;
}

export interface HtmlConfig {
  javascriptEnabled?: boolean;
  scrollEnabled?: boolean;
  baseUrl?: string;
  transparentBackground?: boolean;
}

interface BaseNode {
  id: string;
  layout?: Layout;
  style?: Style;
  styleClass?: string;
  visible?: string;
  actions?: Partial<Record<ActionTrigger, Action>>;
  animation?: Animation;
}

export interface NativeDisplayContainer extends BaseNode {
  type: 'container';
  containerType: ContainerType;
  children: NativeDisplayNode[];
  galleryConfig?: GalleryConfig;
  dividerConfig?: DividerConfig;
}

export interface NativeDisplayElement extends BaseNode {
  type: 'element';
  elementType: ElementType;
  bindings: Record<string, string>;
  dividerConfig?: DividerConfig;
  imageConfig?: ImageConfig;
  htmlConfig?: HtmlConfig;
}

export type NativeDisplayNode = NativeDisplayContainer | NativeDisplayElement;

export function isContainer(node: NativeDisplayNode): node is NativeDisplayContainer {
  return node.type === 'container';
}

export function isElement(node: NativeDisplayNode): node is NativeDisplayElement {
  return node.type === 'element';
}
