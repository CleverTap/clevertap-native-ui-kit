import { GalleryMode, Orientation, SnapBehavior } from './enums';

export interface PeekConfig {
  before: number;
  after: number;
}

export interface IndicatorStyle {
  size?: number;
  spacing?: number;
  activeColor?: string;
  inactiveColor?: string;
  shape?: 'circle' | 'rectangle';
  position?: 'top' | 'bottom' | 'left' | 'right';
}

export interface ArrowStyle {
  size?: number;
  color?: string;
  backgroundColor?: string;
  padding?: number;
}

export interface GalleryConfig {
  mode: GalleryMode;
  orientation?: Orientation;
  snapBehavior?: SnapBehavior;
  peek?: PeekConfig;
  itemsPerView?: number;
  columns?: number;
  spacing?: number;
  showIndicators?: boolean;
  indicatorStyle?: IndicatorStyle;
  autoScrollInterval?: number;
  infiniteScroll?: boolean;
  showArrows?: boolean;
  arrowStyle?: ArrowStyle;
  initialPage?: number;
}
