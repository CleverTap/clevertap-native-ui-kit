enum ContainerType {
  vertical,
  horizontal,
  box,
  gallery;

  static ContainerType fromJson(String value) => switch (value) {
        'vertical' => vertical,
        'horizontal' => horizontal,
        'box' => box,
        'gallery' => gallery,
        _ => box,
      };
}

enum ElementType {
  text,
  image,
  button,
  video,
  spacer,
  divider,
  html;

  static ElementType fromJson(String value) => switch (value) {
        'text' => text,
        'image' => image,
        'button' => button,
        'video' => video,
        'spacer' => spacer,
        'divider' => divider,
        'html' => html,
        _ => text,
      };
}

enum DimensionUnit {
  dp,
  sp,
  percent,
  px;

  static DimensionUnit fromJson(String value) => switch (value) {
        'dp' => dp,
        'sp' => sp,
        'percent' => percent,
        'px' => px,
        _ => dp,
      };
}

enum SpecialDimension {
  wrapContent,
  matchParent;

  static SpecialDimension? fromJson(String? value) => switch (value) {
        'wrap_content' => wrapContent,
        'match_parent' => matchParent,
        _ => null,
      };
}

enum ArrangementStrategy {
  spaced,
  spaceBetween,
  spaceEvenly,
  spaceAround,
  start,
  center,
  end;

  static ArrangementStrategy fromJson(String value) => switch (value) {
        'spaced' => spaced,
        'space_between' => spaceBetween,
        'space_evenly' => spaceEvenly,
        'space_around' => spaceAround,
        'start' => start,
        'center' => center,
        'end' => end,
        _ => spaced,
      };
}

enum GalleryMode {
  snapping,
  freeFlow,
  freeFlowGrid;

  static GalleryMode fromJson(String value) => switch (value) {
        'snapping' => snapping,
        'free_flow' => freeFlow,
        'free_flow_grid' => freeFlowGrid,
        _ => snapping,
      };
}

enum Orientation {
  horizontal,
  vertical;

  static Orientation fromJson(String value) => switch (value) {
        'horizontal' => horizontal,
        'vertical' => vertical,
        _ => horizontal,
      };
}

enum SnapBehavior {
  none,
  start,
  center,
  end;

  static SnapBehavior fromJson(String value) => switch (value) {
        'none' => none,
        'start' => start,
        'center' => center,
        'end' => end,
        _ => center,
      };
}

enum ImageFit {
  crop,
  contain,
  fill,
  tile;

  static ImageFit fromJson(String value) => switch (value) {
        'crop' => crop,
        'contain' => contain,
        'fill' => fill,
        'tile' => tile,
        _ => crop,
      };
}

enum NDFontWeight {
  normal,
  medium,
  bold,
  light;

  static NDFontWeight fromJson(String value) => switch (value) {
        'normal' => normal,
        'medium' => medium,
        'bold' => bold,
        'light' => light,
        _ => normal,
      };
}

enum NDFontStyle {
  normal,
  italic;

  static NDFontStyle fromJson(String value) => switch (value) {
        'normal' => normal,
        'italic' => italic,
        _ => normal,
      };
}

enum NDTextDecoration {
  none,
  underline,
  strikethrough;

  static NDTextDecoration fromJson(String value) => switch (value) {
        'none' => none,
        'underline' => underline,
        'strikethrough' => strikethrough,
        _ => none,
      };
}

enum NDTextOverflow {
  clip,
  ellipsis,
  visible;

  static NDTextOverflow fromJson(String value) => switch (value) {
        'clip' => clip,
        'ellipsis' => ellipsis,
        'visible' => visible,
        _ => ellipsis,
      };
}

enum AnimationType {
  none,
  fadeIn,
  slideInLeft,
  slideInRight,
  slideInTop,
  slideInBottom,
  scaleIn,
  fadeScaleIn,
  fadeSlideIn;

  static AnimationType fromJson(String value) => switch (value) {
        'none' => none,
        'fade_in' => fadeIn,
        'slide_in_left' => slideInLeft,
        'slide_in_right' => slideInRight,
        'slide_in_top' => slideInTop,
        'slide_in_bottom' => slideInBottom,
        'scale_in' => scaleIn,
        'fade_scale_in' => fadeScaleIn,
        'fade_slide_in' => fadeSlideIn,
        _ => none,
      };
}

enum Easing {
  linear,
  easeIn,
  easeOut,
  easeInOut,
  easeInBack,
  easeOutBack,
  spring;

  static Easing fromJson(String value) => switch (value) {
        'linear' => linear,
        'ease_in' => easeIn,
        'ease_out' => easeOut,
        'ease_in_out' => easeInOut,
        'ease_in_back' => easeInBack,
        'ease_out_back' => easeOutBack,
        'spring' => spring,
        _ => easeOut,
      };
}

enum GradientType {
  linear,
  radial,
  sweep;

  static GradientType fromJson(String value) => switch (value) {
        'linear' => linear,
        'radial' => radial,
        'sweep' => sweep,
        _ => linear,
      };
}

enum AnimationStyle {
  smooth,
  shift,
  pulse;

  static AnimationStyle fromJson(String value) => switch (value) {
        'smooth' => smooth,
        'shift' => shift,
        'pulse' => pulse,
        _ => smooth,
      };
}

enum PatternType {
  dots,
  stripesHorizontal,
  stripesVertical,
  stripesDiagonal,
  grid,
  checkerboard,
  polkaDots;

  static PatternType fromJson(String value) => switch (value) {
        'dots' => dots,
        'stripes_horizontal' => stripesHorizontal,
        'stripes_vertical' => stripesVertical,
        'stripes_diagonal' => stripesDiagonal,
        'grid' => grid,
        'checkerboard' => checkerboard,
        'polka_dots' => polkaDots,
        _ => dots,
      };
}

enum ParticleDirection {
  up,
  down,
  left,
  right,
  random;

  static ParticleDirection fromJson(String value) => switch (value) {
        'up' => up,
        'down' => down,
        'left' => left,
        'right' => right,
        'random' => random,
        _ => up,
      };
}

enum ExecutionMode {
  sequential,
  parallel;

  static ExecutionMode fromJson(String value) => switch (value) {
        'sequential' => sequential,
        'parallel' => parallel,
        _ => sequential,
      };
}

enum TextDimensionUnit {
  platform,
  percent;

  static TextDimensionUnit fromJson(String value) => switch (value) {
        'platform' => platform,
        'percent' => percent,
        _ => platform,
      };
}
