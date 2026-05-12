export type ContainerType = 'vertical' | 'horizontal' | 'box' | 'gallery';

export type ElementType = 'text' | 'image' | 'button' | 'video' | 'spacer' | 'divider' | 'html';

export type DimensionUnit = 'dp' | 'sp' | 'percent' | 'px';

export type SpecialDimension = 'wrap_content' | 'match_parent';

export type FontWeight = 'normal' | 'medium' | 'bold' | 'light';

export type FontStyle = 'normal' | 'italic';

export type TextDecoration = 'none' | 'underline' | 'strikethrough';

export type TextOverflow = 'clip' | 'ellipsis' | 'visible';

export type Orientation = 'horizontal' | 'vertical';

export type SnapBehavior = 'none' | 'start' | 'center' | 'end';

export type ArrangementStrategy =
  | 'spaced'
  | 'space_between'
  | 'space_evenly'
  | 'space_around'
  | 'start'
  | 'center'
  | 'end';

export type AnimationType =
  | 'none'
  | 'fade_in'
  | 'slide_in_left'
  | 'slide_in_right'
  | 'slide_in_top'
  | 'slide_in_bottom'
  | 'scale_in'
  | 'fade_scale_in'
  | 'fade_slide_in';

export type EasingType =
  | 'linear'
  | 'ease_in'
  | 'ease_out'
  | 'ease_in_out'
  | 'ease_in_back'
  | 'ease_out_back'
  | 'spring';

export type ImageFit = 'crop' | 'contain' | 'fill' | 'tile';

export type GradientType = 'linear' | 'radial' | 'sweep';

export type AnimationStyle = 'smooth' | 'shift' | 'pulse';

export type PatternType =
  | 'dots'
  | 'stripes_horizontal'
  | 'stripes_vertical'
  | 'stripes_diagonal'
  | 'grid'
  | 'checkerboard'
  | 'polka_dots';

export type ParticleDirection = 'up' | 'down' | 'left' | 'right' | 'random';

export type GalleryMode = 'snapping' | 'free_flow' | 'free_flow_grid';

export type ExecutionMode = 'sequential' | 'parallel';

export type TextDimensionUnit = 'platform' | 'percent';
