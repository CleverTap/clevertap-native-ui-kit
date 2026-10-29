import React, { useEffect, useRef } from 'react';
import { View } from 'react-native';
import { isContainer, isElement } from '../models/NativeDisplayNode';
import { VariableEvaluator } from '../evaluator/VariableEvaluator';
import { useVariables } from '../context/VariablesContext';
import { EntranceAnimation } from './EntranceAnimation';
import { BackgroundRenderer } from './BackgroundRenderer';
import { useRootSize } from '../context/RootSizeContext';
import { resolveBorderRadius } from '../utils/dimension';
import { VerticalContainer } from './containers/VerticalContainer';
import { HorizontalContainer } from './containers/HorizontalContainer';
import { BoxContainer } from './containers/BoxContainer';
import { GalleryContainer } from './containers/GalleryContainer';
import { TextElement } from './elements/TextElement';
import { ImageElement } from './elements/ImageElement';
import { ButtonElement } from './elements/ButtonElement';
import { VideoElement } from './elements/VideoElement';
import { HtmlElement } from './elements/HtmlElement';
import { SpacerElement } from './elements/SpacerElement';
import { DividerElement } from './elements/DividerElement';
import type { RenderNodeProps } from './types';
import { NDLogger } from '../internal/NDLogger';

export type { RenderNodeProps };

// Two-step memo: this inner function refers to the memoized `RenderNode`
// export below when it builds `sharedProps`. If we inlined the memo instead,
// that name would point to the raw function, and containers would get an
// unmemoized reference that breaks their own React.memo.
function RenderNodeFn({ node, resolvedStyles, actionHandler }: RenderNodeProps): React.ReactElement | null {
  // Read variables from context, not props, so RenderNode has a stable
  // reference we can pass to containers and keep their React.memo working.
  const variables = useVariables();
  // Root size anchors percent borderRadius so an element's background wrapper can
  // be clipped to the same rounded corners as the element's border.
  const { height: rootHeight } = useRootSize();
  // Keep the handler in a ref so cleanup sees the latest one without adding
  // actionHandler to the effect deps.
  const actionHandlerRef = useRef(actionHandler);
  actionHandlerRef.current = actionHandler;

  // onAppear fires once on mount, onDisappear fires on unmount.
  useEffect(() => {
    const handler = actionHandlerRef.current;
    const appearAction = node.actions?.onAppear;
    if (appearAction) {
      handler.handleLifecycle(appearAction, node.id, 'appear');
    }
    return () => {
      const disappearAction = node.actions?.onDisappear;
      if (disappearAction) {
        actionHandlerRef.current.handleLifecycle(disappearAction, node.id, 'disappear');
      }
    };
  // Re-run only when the node changes (e.g. a list item gets replaced).
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [node.id]);

  if (node.visible != null) {
    const visibleStr = String(node.visible);
    if (visibleStr === 'false') return null;
    if (visibleStr !== 'true' && visibleStr !== '') {
      const evaluator = new VariableEvaluator(variables ?? {});
      if (!evaluator.evaluateBoolean(visibleStr)) return null;
    }
  }

  const resolvedStyle = resolvedStyles[node.id] ?? {};

  let content: React.ReactElement | null = null;

  if (isContainer(node)) {
    const sharedProps = {
      node,
      resolvedStyle,
      resolvedStyles,
      actionHandler,
      // Pass the memoized RenderNode directly. An inline closure would be a new
      // function each render, which looks like a new prop and defeats container memo.
      RenderNode,
    };

    switch (node.containerType) {
      case 'vertical':
        content = <VerticalContainer {...sharedProps} />;
        break;
      case 'horizontal':
        content = <HorizontalContainer {...sharedProps} />;
        break;
      case 'box':
        content = <BoxContainer {...sharedProps} />;
        break;
      case 'gallery':
        content = <GalleryContainer {...sharedProps} />;
        break;
      default:
        // Unknown container type. Fall back to vertical, but log it so a bad
        // config is visible in logs. Natives warn here too.
        NDLogger.w('RenderNode', `Unknown containerType "${String(node.containerType)}" for node ${node.id}; falling back to vertical.`);
        content = <VerticalContainer {...sharedProps} />;
        break;
    }
  } else if (isElement(node)) {
    switch (node.elementType) {
      case 'text':
        content = <TextElement node={node} resolvedStyle={resolvedStyle} />;
        break;
      case 'image':
        content = <ImageElement node={node} resolvedStyle={resolvedStyle} actionHandler={actionHandler} />;
        break;
      case 'button':
        content = <ButtonElement node={node} resolvedStyle={resolvedStyle} actionHandler={actionHandler} />;
        break;
      case 'video':
        content = <VideoElement node={node} resolvedStyle={resolvedStyle} />;
        break;
      case 'html':
        content = <HtmlElement node={node} resolvedStyle={resolvedStyle} />;
        break;
      case 'spacer':
        content = <SpacerElement node={node} resolvedStyle={resolvedStyle} />;
        break;
      case 'divider':
        content = <DividerElement node={node} resolvedStyle={resolvedStyle} />;
        break;
      default:
        // Natives log a warning for an unknown element type. Match that so a
        // bad config is visible in logs instead of a silent blank.
        NDLogger.w('RenderNode', `Unknown elementType "${String(node.elementType)}" for node ${node.id}; skipping.`);
        return null;
    }
  }

  if (!content) return null;

  // Wrap in an entrance animation if one is set.
  if (node.animation && node.animation.type !== 'none') {
    content = <EntranceAnimation animation={node.animation}>{content}</EntranceAnimation>;
  }

  // Only elements need the background wrapper. Containers draw their own
  // background internally, clipped to their bounds.
  //
  // Clip the wrapper to the element's borderRadius (with overflow: hidden) so a
  // gradient/image fill follows the element's rounded corners instead of showing
  // square corners poking out behind a rounded border (e.g. a pill button).
  if (resolvedStyle.background && !isContainer(node)) {
    const br = resolvedStyle.borderRadius
      ? resolveBorderRadius(resolvedStyle.borderRadius, rootHeight)
      : 0;
    const bgStyle = br > 0 ? { borderRadius: br, overflow: 'hidden' as const } : undefined;
    content = (
      <BackgroundRenderer background={resolvedStyle.background} style={bgStyle}>
        {content}
      </BackgroundRenderer>
    );
  }

  // Offset for children not inside a BOX. BOX handles its own offset as
  // absolute top/left, so this only runs for VERTICAL/HORIZONTAL/GALLERY children.
  // Percent offsets need parent size, which we don't have here.
  const offset = node.layout?.offset;
  if (offset && (offset.x !== 0 || offset.y !== 0)) {
    if (offset.unit === 'percent') {
      NDLogger.w(
        'RenderNode',
        `node ${node.id}: percent offset outside a BOX container is not supported - use a BOX container for percent-based absolute positioning.`,
      );
    } else {
      // dp / sp / px - shift visually, keep the element in the flex flow.
      content = (
        <View style={{ transform: [{ translateX: offset.x }, { translateY: offset.y }] }}>
          {content}
        </View>
      );
    }
  }

  return content;
}

// Memoized export. RenderNodeFn passes this stable reference to containers.
export const RenderNode = React.memo(RenderNodeFn);
