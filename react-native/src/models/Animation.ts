import { AnimationType, EasingType } from './enums';

export interface Animation {
  type: AnimationType;
  duration?: number;
  delay?: number;
  easing?: EasingType;
}
