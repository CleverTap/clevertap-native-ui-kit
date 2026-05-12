import React, { useEffect } from 'react';
import { View } from 'react-native';
import type { Animation } from '../models/Animation';
import { getReanimated } from '../optional/optionalDeps';

interface EntranceAnimationProps {
  animation: Animation;
  children: React.ReactNode;
}

export function EntranceAnimation({ animation, children }: EntranceAnimationProps): React.ReactElement {
  const reanimated = getReanimated();

  if (!reanimated) {
    console.warn('[EntranceAnimation] Entrance animation requires react-native-reanimated. Element will render without animation.');
    return <View>{children}</View>;
  }

  return <AnimatedWrapper animation={animation} reanimated={reanimated}>{children}</AnimatedWrapper>;
}

interface AnimatedWrapperProps {
  animation: Animation;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  reanimated: any;
  children: React.ReactNode;
}

function AnimatedWrapper({ animation, reanimated, children }: AnimatedWrapperProps): React.ReactElement {
  const {
    useSharedValue,
    useAnimatedStyle,
    withTiming,
    withSpring,
    Easing,
  } = reanimated;
  const Animated = reanimated.default ?? reanimated;

  const duration = animation.duration ?? 350;
  const delay = animation.delay ?? 0;
  const easing = resolveEasing(animation.easing, Easing);

  const opacity = useSharedValue(animation.type === 'none' ? 1 : 0);
  const translateY = useSharedValue(
    animation.type === 'slide_in_bottom' ? 40
      : animation.type === 'slide_in_top' ? -40
      : 0,
  );
  const translateX = useSharedValue(
    animation.type === 'slide_in_right' ? 40
      : animation.type === 'slide_in_left' ? -40
      : 0,
  );
  const scale = useSharedValue(
    animation.type === 'scale_in' || animation.type === 'fade_scale_in' ? 0.8 : 1,
  );

  useEffect(() => {
    if (animation.type === 'none') return;

    const config = animation.easing === 'spring'
      ? undefined
      : { duration, easing, delay };

    const animate = animation.easing === 'spring'
      ? (to: number) => withSpring(to, { damping: 15, stiffness: 100, delay })
      : (to: number) => withTiming(to, config);

    opacity.value = animate(1);
    translateY.value = animate(0);
    translateX.value = animate(0);
    scale.value = animate(1);
  }, []);

  const animStyle = useAnimatedStyle(() => ({
    opacity: opacity.value,
    transform: [
      { translateX: translateX.value },
      { translateY: translateY.value },
      { scale: scale.value },
    ],
  }));

  const AnimatedView = Animated.View ?? View;

  return (
    <AnimatedView style={animStyle}>
      {children}
    </AnimatedView>
  );
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function resolveEasing(easing: string | undefined, Easing: any): any {
  switch (easing) {
    case 'linear': return Easing.linear;
    case 'ease_in': return Easing.in(Easing.ease);
    case 'ease_out': return Easing.out(Easing.ease);
    case 'ease_in_out': return Easing.inOut(Easing.ease);
    case 'ease_in_back': return Easing.in(Easing.back(1.5));
    case 'ease_out_back': return Easing.out(Easing.back(1.5));
    default: return Easing.out(Easing.ease);
  }
}
