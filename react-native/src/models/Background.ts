import { AnimationStyle, GradientType, ImageFit, ParticleDirection, PatternType } from './enums';

export interface SolidBackground {
  type: 'solid';
  color: string;
}

export interface LinearGradientBackground {
  type: 'linear_gradient';
  angle: number;
  colors: string[];
  stops?: number[];
}

export interface RadialGradientBackground {
  type: 'radial_gradient';
  center_x?: number;
  center_y?: number;
  radius?: number;
  colors: string[];
  stops?: number[];
}

export interface SweepGradientBackground {
  type: 'sweep_gradient';
  center_x?: number;
  center_y?: number;
  start_angle?: number;
  colors: string[];
  stops?: number[];
}

export interface ImageBackground {
  type: 'image';
  url: string;
  fit?: ImageFit;
  opacity?: number;
  blur?: number;
  tint?: string;
  tint_opacity?: number;
}

export interface ShimmerBackground {
  type: 'shimmer';
  base_color: string;
  highlight_color: string;
  angle?: number;
  duration?: number;
  loop?: boolean;
}

export interface AnimatedGradientBackground {
  type: 'animated_gradient';
  gradient_type: GradientType;
  angle?: number;
  colors: string[];
  duration: number;
  loop?: boolean;
  animation_style?: AnimationStyle;
}

export interface PulseBackground {
  type: 'pulse';
  color: string;
  min_opacity?: number;
  max_opacity?: number;
  duration: number;
  loop?: boolean;
}

export interface PatternBackground {
  type: 'pattern';
  pattern_type: PatternType;
  primary_color: string;
  secondary_color: string;
  size?: number;
  spacing?: number;
  opacity?: number;
}

export interface ParticlesBackground {
  type: 'particles';
  particle_color: string;
  particle_count?: number;
  particle_size?: number;
  speed?: number;
  direction?: ParticleDirection;
  opacity?: number;
}

export interface LayeredBackground {
  type: 'layered';
  layers: Background[];
}

export type Background =
  | SolidBackground
  | LinearGradientBackground
  | RadialGradientBackground
  | SweepGradientBackground
  | ImageBackground
  | ShimmerBackground
  | AnimatedGradientBackground
  | PulseBackground
  | PatternBackground
  | ParticlesBackground
  | LayeredBackground;
