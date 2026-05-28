import React, { useCallback, useEffect, useRef, useState } from 'react';
import { View, FlatList, Pressable, Text } from 'react-native';
import type { ViewStyle } from 'react-native';
import type { NativeDisplayContainer } from '../../models/NativeDisplayNode';
import type { Style } from '../../models/Style';
import type { ResolvedStyles } from '../../models/NativeDisplayConfig';
import type { ActionHandler } from '../../handler/ActionHandler';
import type { RenderNodeProps } from '../types';
import type { ArrowStyle } from '../../models/GalleryConfig';
import { resolveLayoutStyle, resolveNodeStyle } from '../layoutModifier';
import { parseColor } from '../../utils/color';
import { useRootSize } from '../../context/RootSizeContext';
import { BackgroundRenderer } from '../BackgroundRenderer';

interface GalleryContainerProps {
  node: NativeDisplayContainer;
  resolvedStyle: Partial<Style>;
  resolvedStyles: ResolvedStyles;
  actionHandler: ActionHandler;
  RenderNode: React.ComponentType<RenderNodeProps>;
}

// Indicator dots

interface IndicatorProps {
  count: number;
  activeIndex: number;
  activeColor?: string;
  inactiveColor?: string;
  size?: number;
  spacing?: number;
  shape?: 'circle' | 'rectangle';
  vertical?: boolean;
}

function Indicator({
  count,
  activeIndex,
  activeColor = '#FFFFFF',
  inactiveColor = 'rgba(255,255,255,0.4)',
  size = 8,
  spacing = 4,
  shape = 'circle',
  vertical = false,
}: IndicatorProps): React.ReactElement {
  const dots = Array.from({ length: count }, (_, i) => i);
  const borderRadius = shape === 'circle' ? size / 2 : 2;
  return (
    <View
      style={{
        flexDirection: vertical ? 'column' : 'row',
        justifyContent: 'center',
        alignItems: 'center',
        paddingVertical: vertical ? 0 : 6,
        paddingHorizontal: vertical ? 6 : 0,
      }}
    >
      {dots.map((i) => (
        <View
          key={i}
          style={{
            width: size,
            height: size,
            borderRadius,
            backgroundColor:
              i === activeIndex
                ? (parseColor(activeColor) ?? activeColor)
                : (parseColor(inactiveColor) ?? inactiveColor),
            margin: spacing / 2,
          }}
        />
      ))}
    </View>
  );
}

// Arrow navigation buttons

interface ArrowButtonProps {
  direction: 'prev' | 'next';
  isVertical: boolean;
  arrowStyle?: ArrowStyle;
  onPress: () => void;
}

function ArrowButton({ direction, isVertical, arrowStyle: cfg, onPress }: ArrowButtonProps): React.ReactElement {
  const color = cfg?.color ?? '#FFFFFF';
  const bg = cfg?.backgroundColor ?? 'rgba(0,0,0,0.4)';
  const size = cfg?.size ?? 20;
  const pad = cfg?.padding ?? 8;

  // Pick arrow symbol: horizontal uses ‹ ›, vertical uses ∧ ∨
  let symbol: string;
  if (isVertical) {
    symbol = direction === 'prev' ? '∧' : '∨';
  } else {
    symbol = direction === 'prev' ? '‹' : '›';
  }

  // Position: prev button is left/top, next button is right/bottom
  const positionStyle: ViewStyle = { position: 'absolute' };
  if (isVertical) {
    positionStyle[direction === 'prev' ? 'top' : 'bottom'] = 4;
    positionStyle.left = 0;
    positionStyle.right = 0;
    positionStyle.alignItems = 'center';
  } else {
    positionStyle[direction === 'prev' ? 'left' : 'right'] = 4;
    positionStyle.top = 0;
    positionStyle.bottom = 0;
    positionStyle.justifyContent = 'center';
  }

  return (
    <View style={positionStyle} pointerEvents="box-none">
      <Pressable
        onPress={onPress}
        style={{
          backgroundColor: parseColor(bg) ?? bg,
          borderRadius: (size + pad * 2) / 2,
          padding: pad,
          justifyContent: 'center',
          alignItems: 'center',
        }}
      >
        <Text style={{ color: parseColor(color) ?? color, fontSize: size, lineHeight: size * 1.2 }}>
          {symbol}
        </Text>
      </Pressable>
    </View>
  );
}

// GalleryContainer

export const GalleryContainer = React.memo(function GalleryContainer({
  node,
  resolvedStyle,
  resolvedStyles,
  actionHandler,
  RenderNode,
}: GalleryContainerProps): React.ReactElement {
  const { width: rootWidth, height: rootHeight } = useRootSize();
  const layout = node.layout ?? {};
  const layoutStyle = resolveLayoutStyle(layout, rootHeight);
  const nodeStyle = resolveNodeStyle(resolvedStyle, rootHeight);
  const galleryConfig = node.galleryConfig;

  // Config values
  const mode = galleryConfig?.mode ?? 'snapping';
  const orientation = galleryConfig?.orientation ?? 'horizontal';
  const isVertical = orientation === 'vertical';
  const spacing = galleryConfig?.spacing ?? 0;
  const itemsPerView = galleryConfig?.itemsPerView ?? 1;
  const columns = galleryConfig?.columns ?? 1;
  const showIndicators = galleryConfig?.showIndicators ?? false;
  const indicatorStyle = galleryConfig?.indicatorStyle;
  const showArrows = galleryConfig?.showArrows ?? false;
  const arrowStyleCfg = galleryConfig?.arrowStyle;
  const peek = galleryConfig?.peek;
  const snapBehaviorRaw = galleryConfig?.snapBehavior ?? 'start';
  const snapAlignment = snapBehaviorRaw === 'none' ? undefined : snapBehaviorRaw;
  const autoScrollInterval = galleryConfig?.autoScrollInterval;
  const infiniteScroll = galleryConfig?.infiniteScroll ?? false;
  const initialPage = galleryConfig?.initialPage ?? 0;

  // State
  const [activeIndex, setActiveIndex] = useState(initialPage);
  const activeIndexRef = useRef(initialPage);
  const flatListRef = useRef<FlatList>(null);

  // Container dimensions
  const containerWidth =
    typeof layoutStyle.width === 'number' ? layoutStyle.width : rootWidth;
  const containerHeight =
    typeof layoutStyle.height === 'number' ? layoutStyle.height : rootHeight;

  // Item size
  const peekBefore = peek?.before ?? 0;
  const peekAfter = peek?.after ?? 0;

  let itemWidth: number;
  let itemHeight: number | undefined;

  if (isVertical) {
    // Vertical gallery: each item fills the full width (cross-axis).
    // itemsPerView controls how many items are visible along the scroll axis.
    if (mode === 'free_flow_grid' && columns > 1) {
      // Multi-column vertical grid: size items to fit `columns` per row
      itemWidth = (containerWidth - spacing * (columns - 1)) / columns;
    } else {
      itemWidth = containerWidth;
    }
    if (mode === 'snapping') {
      itemHeight = containerHeight - peekBefore - peekAfter;
    } else if (mode === 'free_flow_grid') {
      itemHeight = (containerHeight - spacing * (itemsPerView - 1)) / itemsPerView;
    }
    // free_flow vertical: items render at their own natural height
  } else {
    // Horizontal gallery
    if (mode === 'free_flow_grid') {
      if (columns > 1) {
        // Multi-row horizontal grid: group items into rows of `columns` each.
        // Item width is derived from itemsPerView (visible columns per screen).
        itemWidth = (containerWidth - spacing * (itemsPerView - 1)) / itemsPerView;
      } else {
        itemWidth = (containerWidth - spacing * (itemsPerView - 1)) / itemsPerView;
      }
    } else if (mode === 'snapping') {
      itemWidth = containerWidth - peekBefore - peekAfter;
    } else {
      // free_flow: items render at their own natural width
      itemWidth = containerWidth;
    }
  }

  // Scroll helpers
  const scrollToIndex = useCallback((index: number, animated: boolean) => {
    flatListRef.current?.scrollToIndex({ index, animated });
  }, []);

  const scrollToPrev = useCallback(() => {
    const count = node.children.length;
    const current = activeIndexRef.current;
    let next = current - 1;
    if (next < 0) {
      next = infiniteScroll ? count - 1 : 0;
    }
    if (next !== current) {
      activeIndexRef.current = next;
      setActiveIndex(next);
      scrollToIndex(next, true);
    }
  }, [infiniteScroll, node.children.length, scrollToIndex]);

  const scrollToNext = useCallback(() => {
    const count = node.children.length;
    const current = activeIndexRef.current;
    let next = current + 1;
    if (next >= count) {
      next = infiniteScroll ? 0 : count - 1;
    }
    if (next !== current) {
      activeIndexRef.current = next;
      setActiveIndex(next);
      scrollToIndex(next, true);
    }
  }, [infiniteScroll, node.children.length, scrollToIndex]);

  // Auto-scroll
  useEffect(() => {
    if (!autoScrollInterval || autoScrollInterval <= 0 || node.children.length <= 1) return;

    const count = node.children.length;
    const timer = setInterval(() => {
      const current = activeIndexRef.current;
      let next = current + 1;
      let animated = true;

      if (next >= count) {
        if (infiniteScroll) {
          // Jump back to the start instantly so the loop appears seamless
          next = 0;
          animated = false;
        } else {
          return; // stop at last item
        }
      }

      activeIndexRef.current = next;
      setActiveIndex(next);
      scrollToIndex(next, animated);
    }, autoScrollInterval);

    return () => clearInterval(timer);
  }, [autoScrollInterval, infiniteScroll, node.children.length, scrollToIndex]);

  // FlatList callbacks
  const keyExtractor = useCallback((item: typeof node.children[0]) => item.id, []);

  const onViewableItemsChanged = useCallback(
    ({ viewableItems }: { viewableItems: Array<{ index: number | null }> }) => {
      if (viewableItems.length > 0 && viewableItems[0]!.index != null) {
        const idx = viewableItems[0]!.index;
        activeIndexRef.current = idx;
        setActiveIndex(idx);
      }
    },
    [],
  );

  // Item renderer
  const renderItem = useCallback(
    ({ item }: { item: typeof node.children[0] }) => {
      const wrapStyle: ViewStyle = {};
      if (!isVertical) {
        if (mode !== 'free_flow') wrapStyle.width = itemWidth;
        if (mode === 'free_flow_grid' && itemHeight !== undefined) wrapStyle.height = itemHeight;
      } else {
        wrapStyle.width = itemWidth;
        if (mode !== 'free_flow' && itemHeight !== undefined) wrapStyle.height = itemHeight;
      }
      return (
        <View style={Object.keys(wrapStyle).length > 0 ? wrapStyle : undefined}>
          <RenderNode
            node={item}
            resolvedStyles={resolvedStyles}
            actionHandler={actionHandler}
          />
        </View>
      );
    },
    [isVertical, mode, itemWidth, itemHeight, resolvedStyles, actionHandler, RenderNode],
  );

  // Separator between items
  const ItemSeparator = useCallback(
    () =>
      spacing > 0 ? (
        <View style={isVertical ? { height: spacing } : { width: spacing }} />
      ) : null,
    [spacing, isVertical],
  );

  // Paging and snap settings
  const pagingEnabled = mode === 'snapping' && !peek;
  const snapToInterval =
    mode === 'snapping' && peek
      ? (isVertical ? (itemHeight ?? 0) : itemWidth) + spacing
      : undefined;

  const contentPaddingStart = peekBefore > 0 ? peekBefore : undefined;
  const contentPaddingEnd = peekAfter > 0 ? peekAfter : undefined;

  // getItemLayout requires a known item size - not available in free_flow mode
  const knownItemSize = isVertical ? itemHeight : itemWidth;
  const getItemLayout =
    mode !== 'free_flow' && knownItemSize !== undefined
      ? (_: unknown, index: number) => ({
          length: knownItemSize + spacing,
          offset: (knownItemSize + spacing) * index,
          index,
        })
      : undefined;

  return (
    <View style={[layoutStyle, nodeStyle, { position: 'relative' }]}>
      {resolvedStyle.background && (
        <BackgroundRenderer
          background={resolvedStyle.background}
          // Explicit width/height: '100%' resolves reliably against the parent's
          // measured size, including wrap_content containers. absoluteFillObject's
          // right:0/bottom:0 inset anchoring fails for wrap_content parents on iOS,
          // leaving the underlying LinearGradient at zero height.
          style={{ position: 'absolute', top: 0, left: 0, width: '100%', height: '100%' }}
        >
          {null}
        </BackgroundRenderer>
      )}
      <FlatList
        // FlatList does not allow numColumns to change after mount. Key on the
        // values that affect it so any config change forces a remount.
        key={`${mode}-${orientation}-${columns}`}
        ref={flatListRef}
        data={node.children}
        horizontal={!isVertical}
        keyExtractor={keyExtractor}
        renderItem={renderItem}
        ItemSeparatorComponent={ItemSeparator}
        pagingEnabled={pagingEnabled}
        snapToInterval={snapToInterval}
        snapToAlignment={snapAlignment}
        decelerationRate="fast"
        showsHorizontalScrollIndicator={false}
        showsVerticalScrollIndicator={false}
        contentContainerStyle={
          contentPaddingStart != null || contentPaddingEnd != null
            ? isVertical
              ? { paddingTop: contentPaddingStart, paddingBottom: contentPaddingEnd }
              : { paddingStart: contentPaddingStart, paddingEnd: contentPaddingEnd }
            : undefined
        }
        onViewableItemsChanged={
          showIndicators || showArrows ? onViewableItemsChanged : undefined
        }
        viewabilityConfig={{ itemVisiblePercentThreshold: 50 }}
        initialScrollIndex={initialPage > 0 ? initialPage : undefined}
        getItemLayout={getItemLayout}
        // Multi-column grid (vertical scroll only - FlatList numColumns requires vertical orientation)
        numColumns={!isVertical || mode !== 'free_flow_grid' ? undefined : columns > 1 ? columns : undefined}
      />

      {showIndicators && (
        <Indicator
          count={node.children.length}
          activeIndex={activeIndex}
          activeColor={indicatorStyle?.activeColor}
          inactiveColor={indicatorStyle?.inactiveColor}
          size={indicatorStyle?.size}
          spacing={indicatorStyle?.spacing}
          shape={indicatorStyle?.shape}
          vertical={isVertical}
        />
      )}

      {showArrows && node.children.length > 1 && (
        <>
          <ArrowButton
            direction="prev"
            isVertical={isVertical}
            arrowStyle={arrowStyleCfg}
            onPress={scrollToPrev}
          />
          <ArrowButton
            direction="next"
            isVertical={isVertical}
            arrowStyle={arrowStyleCfg}
            onPress={scrollToNext}
          />
        </>
      )}
    </View>
  );
});
