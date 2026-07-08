import React, { useEffect } from 'react';
import { View, Image, StyleSheet } from 'react-native';
import type { ViewStyle } from 'react-native';
import type { Background } from '../models/Background';
import { parseColor } from '../utils/color';
import { getLinearGradient, getSvg, getReanimated, getBlurView } from '../optional/optionalDeps';
import { NDLogger } from '../internal/NDLogger';

interface BackgroundRendererProps {
  background: Background;
  style?: ViewStyle;
  children: React.ReactNode;
}

function SolidBg({ color, style, children }: { color: string; style?: ViewStyle; children: React.ReactNode }): React.ReactElement {
  return (
    <View style={[style, { backgroundColor: parseColor(color) ?? color }]}>
      {children}
    </View>
  );
}

function LinearGradientBg({
  background,
  style,
  children,
}: {
  background: import('../models/Background').LinearGradientBackground;
  style?: ViewStyle;
  children: React.ReactNode;
}): React.ReactElement {
  const LinearGradient = getLinearGradient();
  const parsedColors = background.colors.map((c) => parseColor(c) ?? c);

  if (!LinearGradient) {
    NDLogger.w('BackgroundRenderer', 'linear_gradient requires react-native-linear-gradient (or expo-linear-gradient for Expo). Falling back to solid color.');
    return (
      <View style={[style, { backgroundColor: parsedColors[0] ?? 'transparent' }]}>
        {children}
      </View>
    );
  }

  const angleRad = (((background.angle ?? 0) - 90) * Math.PI) / 180;
  const startX = 0.5 - Math.cos(angleRad) * 0.5;
  const startY = 0.5 - Math.sin(angleRad) * 0.5;
  const endX = 0.5 + Math.cos(angleRad) * 0.5;
  const endY = 0.5 + Math.sin(angleRad) * 0.5;

  // Pass color stops as `locations` so uneven gradients match native. Only when
  // the count matches the colors, since the library misbehaves otherwise; then
  // we let it space them evenly.
  const locations =
    background.stops && background.stops.length === parsedColors.length
      ? background.stops
      : undefined;

  // Wrapper View owns the size/position; the gradient fills it at 100%x100%.
  // absoluteFill (bottom/right: 0) on the gradient is unreliable when the parent
  // gets its height from aspectRatio, but 100% always resolves against it.
  return (
    <View style={style}>
      <LinearGradient
        colors={parsedColors}
        locations={locations}
        start={{ x: startX, y: startY }}
        end={{ x: endX, y: endY }}
        style={{ position: 'absolute', width: '100%', height: '100%' }}
      >
        {null}
      </LinearGradient>
      {children}
    </View>
  );
}

function SvgGradientBg({
  background,
  style,
  children,
}: {
  background: import('../models/Background').RadialGradientBackground | import('../models/Background').SweepGradientBackground;
  style?: ViewStyle;
  children: React.ReactNode;
}): React.ReactElement {
  const svgMod = getSvg();
  const parsedColors = background.colors.map((c) => parseColor(c) ?? c);

  if (!svgMod) {
    NDLogger.w('BackgroundRenderer', `${background.type} requires react-native-svg. Falling back to solid color.`);
    return (
      <View style={[style, { backgroundColor: parsedColors[0] ?? 'transparent' }]}>
        {children}
      </View>
    );
  }

  const { Svg, Defs, RadialGradient: SvgRadial, LinearGradient: SvgLinear, Stop, Rect } = svgMod;

  if (background.type === 'radial_gradient') {
    const bg = background as import('../models/Background').RadialGradientBackground;
    const stops = bg.stops ?? bg.colors.map((_, i) => i / Math.max(bg.colors.length - 1, 1));
    return (
      <View style={[style, { overflow: 'hidden' }]}>
        <Svg style={StyleSheet.absoluteFill}>
          <Defs>
            <SvgRadial
              id="rg"
              cx={`${(bg.center_x ?? 50)}%`}
              cy={`${(bg.center_y ?? 50)}%`}
              r={`${(bg.radius ?? 50)}%`}
            >
              {parsedColors.map((color, i) => (
                <Stop key={i} offset={`${stops[i] * 100}%`} stopColor={color} />
              ))}
            </SvgRadial>
          </Defs>
          <Rect x="0" y="0" width="100%" height="100%" fill="url(#rg)" />
        </Svg>
        {children}
      </View>
    );
  }

  // sweep_gradient - approximated with a linear gradient (true sweep is complex in SVG)
  const bg = background as import('../models/Background').SweepGradientBackground;
  const stops = bg.stops ?? bg.colors.map((_, i) => i / Math.max(bg.colors.length - 1, 1));
  return (
    <View style={[style, { overflow: 'hidden' }]}>
      <Svg style={StyleSheet.absoluteFill}>
        <Defs>
          <SvgLinear id="sg" x1="0%" y1="0%" x2="100%" y2="100%">
            {parsedColors.map((color, i) => (
              <Stop key={i} offset={`${stops[i] * 100}%`} stopColor={color} />
            ))}
          </SvgLinear>
        </Defs>
        <Rect x="0" y="0" width="100%" height="100%" fill="url(#sg)" />
      </Svg>
      {children}
    </View>
  );
}

function AnimatedGradientBg({
  background,
  style,
  children,
}: {
  background: import('../models/Background').AnimatedGradientBackground;
  style?: ViewStyle;
  children: React.ReactNode;
}): React.ReactElement {
  const reanimated = getReanimated();
  const parsedColors = background.colors.map((c) => parseColor(c) ?? c);

  if (!reanimated) {
    NDLogger.w('BackgroundRenderer', 'animated_gradient requires react-native-reanimated. Falling back to solid color.');
    return (
      <View style={[style, { backgroundColor: parsedColors[0] ?? 'transparent' }]}>
        {children}
      </View>
    );
  }

  const LinearGradient = getLinearGradient();
  if (!LinearGradient) {
    NDLogger.w('BackgroundRenderer', 'animated_gradient requires react-native-linear-gradient (or expo-linear-gradient for Expo). Falling back to solid color.');
    return (
      <View style={[style, { backgroundColor: parsedColors[0] ?? 'transparent' }]}>
        {children}
      </View>
    );
  }

  const { useSharedValue, useAnimatedStyle, withRepeat, withTiming, Easing } = reanimated;
  const AnimatedLinearGradient = reanimated.default?.createAnimatedComponent
    ? reanimated.default.createAnimatedComponent(LinearGradient)
    : LinearGradient;

  // Cycle through the colors (simplified)
  const progress = useSharedValue(0);
  useEffect(() => {
    progress.value = withRepeat(
      withTiming(1, { duration: background.duration, easing: Easing.linear }),
      -1,
      false,
    );
  }, []);

  const angleRad = (((background.angle ?? 0) - 90) * Math.PI) / 180;
  const startX = 0.5 - Math.cos(angleRad) * 0.5;
  const startY = 0.5 - Math.sin(angleRad) * 0.5;
  const endX = 0.5 + Math.cos(angleRad) * 0.5;
  const endY = 0.5 + Math.sin(angleRad) * 0.5;

  // Same wrapper-View trick as LinearGradientBg: 100%x100% fills the outer View
  // no matter how the parent got its size.
  return (
    <View style={style}>
      <AnimatedLinearGradient
        colors={parsedColors}
        start={{ x: startX, y: startY }}
        end={{ x: endX, y: endY }}
        style={{ position: 'absolute', width: '100%', height: '100%' }}
      >
        {null}
      </AnimatedLinearGradient>
      {children}
    </View>
  );
}

function ShimmerBg({
  background,
  style,
  children,
}: {
  background: import('../models/Background').ShimmerBackground;
  style?: ViewStyle;
  children: React.ReactNode;
}): React.ReactElement {
  const reanimated = getReanimated();
  const baseColor = parseColor(background.base_color) ?? '#E0E0E0';
  const highlightColor = parseColor(background.highlight_color) ?? '#F5F5F5';

  if (!reanimated) {
    NDLogger.w('BackgroundRenderer', 'shimmer requires react-native-reanimated. Falling back to static base color.');
    return (
      <View style={[style, { backgroundColor: baseColor }]}>
        {children}
      </View>
    );
  }

  const { useSharedValue, useAnimatedStyle, withRepeat, withTiming, Easing } = reanimated;
  const Animated_View = reanimated.default?.View ?? View;

  const progress = useSharedValue(-1);
  useEffect(() => {
    progress.value = withRepeat(
      withTiming(1, { duration: background.duration ?? 1200, easing: Easing.linear }),
      -1,
      false,
    );
  }, []);

  const animStyle = useAnimatedStyle(() => ({
    opacity: 0.3 + 0.7 * Math.abs(progress.value),
  }));

  return (
    <View style={[style, { backgroundColor: baseColor, overflow: 'hidden' }]}>
      <Animated_View
        style={[StyleSheet.absoluteFill, animStyle, { backgroundColor: highlightColor }]}
      />
      {children}
    </View>
  );
}

function PulseBg({
  background,
  style,
  children,
}: {
  background: import('../models/Background').PulseBackground;
  style?: ViewStyle;
  children: React.ReactNode;
}): React.ReactElement {
  const reanimated = getReanimated();
  const color = parseColor(background.color) ?? '#FFFFFF';

  if (!reanimated) {
    NDLogger.w('BackgroundRenderer', 'pulse requires react-native-reanimated. Falling back to static color.');
    return (
      <View style={[style, { backgroundColor: color }]}>
        {children}
      </View>
    );
  }

  const { useSharedValue, useAnimatedStyle, withRepeat, withTiming, Easing } = reanimated;
  const Animated_View = reanimated.default?.View ?? View;

  const minOpacity = background.min_opacity ?? 0.5;
  const maxOpacity = background.max_opacity ?? 1.0;

  const opacity = useSharedValue(minOpacity);
  useEffect(() => {
    opacity.value = withRepeat(
      withTiming(maxOpacity, { duration: background.duration ?? 800, easing: Easing.inOut(Easing.ease) }),
      -1,
      true,
    );
  }, []);

  const animStyle = useAnimatedStyle(() => ({ opacity: opacity.value }));

  return (
    <Animated_View style={[style, { backgroundColor: color }, animStyle]}>
      {children}
    </Animated_View>
  );
}

function ImageBg({
  background,
  style,
  children,
}: {
  background: import('../models/Background').ImageBackground;
  style?: ViewStyle;
  children: React.ReactNode;
}): React.ReactElement {
  const BlurView = getBlurView();

  const resizeModeMap: Record<string, 'cover' | 'contain' | 'stretch' | 'repeat'> = {
    crop: 'cover',
    contain: 'contain',
    fill: 'stretch',
    tile: 'repeat',
  };
  const resizeMode = resizeModeMap[background.fit ?? 'crop'] ?? 'cover';

  return (
    <View style={[style, { overflow: 'hidden' }]}>
      <Image
        source={{ uri: background.url }}
        style={[StyleSheet.absoluteFill, { resizeMode }]}
        blurRadius={background.blur ?? 0}
      />
      {background.tint && (
        <View
          style={[
            StyleSheet.absoluteFill,
            { backgroundColor: parseColor(background.tint), opacity: background.tint_opacity ?? 1 },
          ]}
        />
      )}
      {children}
    </View>
  );
}

function PatternBg({
  background,
  style,
  children,
}: {
  background: import('../models/Background').PatternBackground;
  style?: ViewStyle;
  children: React.ReactNode;
}): React.ReactElement {
  const svgMod = getSvg();
  // Base fill = primary_color, pattern shapes = secondary_color, matching native.
  // (These were swapped before, so patterns showed the wrong colors.)
  const primaryColor = parseColor(background.primary_color) ?? '#808080';
  const secondaryColor = parseColor(background.secondary_color) ?? '#FFFFFF';

  if (!svgMod) {
    NDLogger.w('BackgroundRenderer', 'pattern requires react-native-svg. Falling back to solid color.');
    return (
      <View style={[style, { backgroundColor: primaryColor }]}>
        {children}
      </View>
    );
  }

  const { Svg, Rect, Circle, Line, Defs, Pattern } = svgMod;
  // Defaults match native (size = 20, spacing = 30).
  const size = background.size ?? 20;
  const spacing = background.spacing ?? 30;
  const opacity = background.opacity ?? 1;

  // Each pattern is a repeating tile (tileW x tileH) with shapes in
  // secondaryColor. SVG <Pattern> tiles it, doing what native's draw loops do.
  let tileW = size + spacing;
  let tileH = size + spacing;
  let patternContent: React.ReactElement;
  switch (background.pattern_type) {
    case 'dots':
    case 'polka_dots':
      // Dot of diameter `size`, centered in a `spacing`-wide tile
      tileW = spacing;
      tileH = spacing;
      patternContent = <Circle cx={spacing / 2} cy={spacing / 2} r={size / 2} fill={secondaryColor} />;
      break;
    case 'stripes_horizontal':
      // Horizontal bar of height `size`, repeated down the tile
      patternContent = <Rect x="0" y="0" width={tileW} height={size} fill={secondaryColor} />;
      break;
    case 'stripes_vertical':
      // Vertical bar of width `size`, repeated across the tile
      patternContent = <Rect x="0" y="0" width={size} height={tileH} fill={secondaryColor} />;
      break;
    case 'stripes_diagonal':
      // Corner-to-corner line of width `size`, tiles seamlessly at 45deg
      patternContent = (
        <Line x1="0" y1="0" x2={tileW} y2={tileH} stroke={secondaryColor} strokeWidth={size} />
      );
      break;
    case 'grid':
      // Horizontal + vertical bars make a grid of `size`-wide lines
      patternContent = (
        <>
          <Rect x="0" y="0" width={tileW} height={size} fill={secondaryColor} />
          <Rect x="0" y="0" width={size} height={tileH} fill={secondaryColor} />
        </>
      );
      break;
    case 'checkerboard':
      // Two `size` squares on the diagonal of a 2x size tile
      tileW = size * 2;
      tileH = size * 2;
      patternContent = (
        <>
          <Rect x="0" y="0" width={size} height={size} fill={secondaryColor} />
          <Rect x={size} y={size} width={size} height={size} fill={secondaryColor} />
        </>
      );
      break;
    default:
      tileW = spacing;
      tileH = spacing;
      patternContent = <Circle cx={spacing / 2} cy={spacing / 2} r={size / 2} fill={secondaryColor} />;
  }

  return (
    <View style={[style, { overflow: 'hidden' }]}>
      <View style={[StyleSheet.absoluteFill, { backgroundColor: primaryColor }]} />
      <Svg style={[StyleSheet.absoluteFill, { opacity }]}>
        <Defs>
          <Pattern id="pat" x="0" y="0" width={tileW} height={tileH} patternUnits="userSpaceOnUse">
            {patternContent}
          </Pattern>
        </Defs>
        <Rect x="0" y="0" width="100%" height="100%" fill="url(#pat)" />
      </Svg>
      {children}
    </View>
  );
}

function ParticlesBg({
  background,
  style,
  children,
}: {
  background: import('../models/Background').ParticlesBackground;
  style?: ViewStyle;
  children: React.ReactNode;
}): React.ReactElement {
  const reanimated = getReanimated();
  const bgColor = 'transparent';
  const particleColor = parseColor(background.particle_color) ?? '#FFFFFF';

  if (!reanimated) {
    NDLogger.w('BackgroundRenderer', 'particles requires react-native-reanimated. Falling back to transparent background.');
    return (
      <View style={[style, { backgroundColor: bgColor }]}>
        {children}
      </View>
    );
  }

  // Simplified: static dots instead of a real particle system
  const count = Math.min(background.particle_count ?? 20, 50);
  const size = background.particle_size ?? 4;
  const opacity = background.opacity ?? 0.7;

  const particles = Array.from({ length: count }, (_, i) => ({
    id: i,
    top: `${(i * 97) % 100}%`,
    left: `${(i * 73 + 13) % 100}%`,
  }));

  return (
    <View style={[style, { overflow: 'hidden' }]}>
      {particles.map((p) => (
        <View
          key={p.id}
          style={{
            position: 'absolute',
            top: p.top as `${number}%`,
            left: p.left as `${number}%`,
            width: size,
            height: size,
            borderRadius: size / 2,
            backgroundColor: particleColor,
            opacity,
          }}
        />
      ))}
      {children}
    </View>
  );
}

function LayeredBg({
  background,
  style,
  children,
}: {
  background: import('../models/Background').LayeredBackground;
  style?: ViewStyle;
  children: React.ReactNode;
}): React.ReactElement {
  const layers = background.layers;
  if (layers.length === 0) {
    return <View style={style}>{children}</View>;
  }

  return (
    <View style={[style, { overflow: 'hidden' }]}>
      {layers.map((layer, i) => (
        <BackgroundRenderer
          key={i}
          background={layer}
          style={StyleSheet.absoluteFillObject}
        >
          {null}
        </BackgroundRenderer>
      ))}
      {children}
    </View>
  );
}

export function BackgroundRenderer({ background, style, children }: BackgroundRendererProps): React.ReactElement {
  switch (background.type) {
    case 'solid':
      return <SolidBg color={background.color} style={style}>{children}</SolidBg>;

    case 'linear_gradient':
      return <LinearGradientBg background={background} style={style}>{children}</LinearGradientBg>;

    case 'radial_gradient':
    case 'sweep_gradient':
      return <SvgGradientBg background={background} style={style}>{children}</SvgGradientBg>;

    case 'animated_gradient':
      return <AnimatedGradientBg background={background} style={style}>{children}</AnimatedGradientBg>;

    case 'shimmer':
      return <ShimmerBg background={background} style={style}>{children}</ShimmerBg>;

    case 'pulse':
      return <PulseBg background={background} style={style}>{children}</PulseBg>;

    case 'image':
      return <ImageBg background={background} style={style}>{children}</ImageBg>;

    case 'pattern':
      return <PatternBg background={background} style={style}>{children}</PatternBg>;

    case 'particles':
      return <ParticlesBg background={background} style={style}>{children}</ParticlesBg>;

    case 'layered':
      return <LayeredBg background={background} style={style}>{children}</LayeredBg>;

    default:
      return <View style={style}>{children}</View>;
  }
}
