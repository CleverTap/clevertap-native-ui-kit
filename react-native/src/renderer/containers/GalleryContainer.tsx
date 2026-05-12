import React, { useCallback, useRef, useState } from 'react';
import { View, FlatList } from 'react-native';
import type { ViewStyle } from 'react-native';
import type { NativeDisplayContainer } from '../../models/NativeDisplayNode';
import type { Style } from '../../models/Style';
import type { ResolvedStyles } from '../../models/NativeDisplayConfig';
import type { ActionHandler } from '../../handler/ActionHandler';
import type { RenderNodeProps } from '../types';
import { resolveLayoutStyle, resolveNodeStyle } from '../layoutModifier';
import { parseColor } from '../../utils/color';
import { useRootSize } from '../../context/RootSizeContext';

interface GalleryContainerProps {
  node: NativeDisplayContainer;
  resolvedStyle: Partial<Style>;
  resolvedStyles: ResolvedStyles;
  actionHandler: ActionHandler;
  RenderNode: React.ComponentType<RenderNodeProps>;
}

interface IndicatorProps {
  count: number;
  activeIndex: number;
  activeColor?: string;
  inactiveColor?: string;
  size?: number;
  spacing?: number;
  shape?: 'circle' | 'rectangle';
}

function Indicator({ count, activeIndex, activeColor = '#FFFFFF', inactiveColor = 'rgba(255,255,255,0.4)', size = 8, spacing = 4, shape = 'circle' }: IndicatorProps): React.ReactElement {
  const dots = Array.from({ length: count }, (_, i) => i);
  const borderRadius = shape === 'circle' ? size / 2 : 2;
  return (
    <View style={{ flexDirection: 'row', justifyContent: 'center', alignItems: 'center', paddingVertical: 6 }}>
      {dots.map((i) => (
        <View
          key={i}
          style={{
            width: size,
            height: size,
            borderRadius,
            backgroundColor: i === activeIndex
              ? (parseColor(activeColor) ?? activeColor)
              : (parseColor(inactiveColor) ?? inactiveColor),
            marginHorizontal: spacing / 2,
          }}
        />
      ))}
    </View>
  );
}

export function GalleryContainer({
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

  const mode = galleryConfig?.mode ?? 'snapping';
  const spacing = galleryConfig?.spacing ?? 0;
  const itemsPerView = galleryConfig?.itemsPerView ?? 1;
  const showIndicators = galleryConfig?.showIndicators ?? false;
  const indicatorStyle = galleryConfig?.indicatorStyle;
  const peek = galleryConfig?.peek;

  const [activeIndex, setActiveIndex] = useState(galleryConfig?.initialPage ?? 0);
  const flatListRef = useRef<FlatList>(null);

  const containerWidth = typeof layoutStyle.width === 'number'
    ? layoutStyle.width
    : rootWidth;

  const peekBefore = peek?.before ?? 0;
  const peekAfter = peek?.after ?? 0;

  let itemWidth: number;
  if (mode === 'free_flow_grid') {
    itemWidth = (containerWidth - spacing * (itemsPerView - 1)) / itemsPerView;
  } else if (mode === 'snapping') {
    itemWidth = containerWidth - peekBefore - peekAfter;
  } else {
    // free_flow: items render at their own width
    itemWidth = containerWidth;
  }

  const keyExtractor = useCallback((item: typeof node.children[0]) => item.id, []);

  const renderItem = useCallback(({ item }: { item: typeof node.children[0] }) => {
    return (
      <View style={{ width: mode === 'free_flow' ? undefined : itemWidth }}>
        <RenderNode
          node={item}
          resolvedStyles={resolvedStyles}
          actionHandler={actionHandler}
        />
      </View>
    );
  }, [itemWidth, mode, resolvedStyles, actionHandler, RenderNode]);

  const ItemSeparator = useCallback(() => (
    spacing > 0 ? <View style={{ width: spacing }} /> : null
  ), [spacing]);

  const onViewableItemsChanged = useCallback(({ viewableItems }: { viewableItems: Array<{ index: number | null }> }) => {
    if (viewableItems.length > 0 && viewableItems[0]!.index != null) {
      setActiveIndex(viewableItems[0]!.index);
    }
  }, []);

  const pagingEnabled = mode === 'snapping' && !peek;
  const snapToInterval = mode === 'snapping' && peek ? itemWidth + spacing : undefined;

  const contentPaddingStart = peekBefore > 0 ? peekBefore : undefined;
  const contentPaddingEnd = peekAfter > 0 ? peekAfter : undefined;

  return (
    <View style={[layoutStyle, nodeStyle]}>
      <FlatList
        ref={flatListRef}
        data={node.children}
        horizontal
        keyExtractor={keyExtractor}
        renderItem={renderItem}
        ItemSeparatorComponent={ItemSeparator}
        pagingEnabled={pagingEnabled}
        snapToInterval={snapToInterval}
        snapToAlignment="start"
        decelerationRate="fast"
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={
          contentPaddingStart != null || contentPaddingEnd != null
            ? { paddingStart: contentPaddingStart, paddingEnd: contentPaddingEnd }
            : undefined
        }
        onViewableItemsChanged={showIndicators ? onViewableItemsChanged : undefined}
        viewabilityConfig={{ itemVisiblePercentThreshold: 50 }}
        initialScrollIndex={galleryConfig?.initialPage ?? 0}
        getItemLayout={
          mode !== 'free_flow'
            ? (_, index) => ({
                length: itemWidth + spacing,
                offset: (itemWidth + spacing) * index,
                index,
              })
            : undefined
        }
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
        />
      )}
    </View>
  );
}
