import React, { useEffect, useRef } from 'react';
import { View } from 'react-native';
import { isContainer, isElement } from '../models/NativeDisplayNode';
import { VariableEvaluator } from '../evaluator/VariableEvaluator';
import { EntranceAnimation } from './EntranceAnimation';
import { BackgroundRenderer } from './BackgroundRenderer';
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

export type { RenderNodeProps };

export function RenderNode({ node, resolvedStyles, actionHandler, variables }: RenderNodeProps): React.ReactElement | null {
  // Stable ref so lifecycle cleanup always sees the current handler without
  // the effect needing actionHandler in its dependency array.
  const actionHandlerRef = useRef(actionHandler);
  actionHandlerRef.current = actionHandler;

  // Lifecycle actions: onAppear fires once on mount, onDisappear on unmount.
  // Matches Android's LaunchedEffect / DisposableEffect pattern in applyClickable().
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
  // Re-run only if the node identity changes (e.g. item replaced in a list).
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [node.id]);

  // Visibility check
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
      RenderNode: (props: RenderNodeProps) => (
        <RenderNode {...props} variables={variables} />
      ),
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
        content = <VerticalContainer {...sharedProps} />;
        break;
    }
  } else if (isElement(node)) {
    switch (node.elementType) {
      case 'text':
        content = <TextElement node={node} resolvedStyle={resolvedStyle} />;
        break;
      case 'image':
        content = <ImageElement node={node} resolvedStyle={resolvedStyle} />;
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
        return null;
    }
  }

  if (!content) return null;

  // Wrap in entrance animation if specified and not 'none'
  if (node.animation && node.animation.type !== 'none') {
    content = <EntranceAnimation animation={node.animation}>{content}</EntranceAnimation>;
  }

  // Wrap in background renderer if a background is defined
  if (resolvedStyle.background) {
    content = (
      <BackgroundRenderer background={resolvedStyle.background}>
        {content}
      </BackgroundRenderer>
    );
  }

  // Apply layout offset for non-BOX container children.
  // BOX containers clear layout.offset from childForRender after consuming it as
  // absolute top/left, so this path only fires for VERTICAL/HORIZONTAL/GALLERY children.
  // Percent offsets outside a BOX cannot be resolved without parent dimensions.
  // Matches Android's Modifier.applyOffset() which uses Modifier.offset() (no layout shift).
  const offset = node.layout?.offset;
  if (offset && (offset.x !== 0 || offset.y !== 0)) {
    if (offset.unit === 'percent') {
      console.warn(
        `[RenderNode] node ${node.id}: percent offset outside a BOX container is not supported — use a BOX container for percent-based absolute positioning.`,
      );
    } else {
      // dp / sp / px — shift visually without removing element from flex flow
      content = (
        <View style={{ transform: [{ translateX: offset.x }, { translateY: offset.y }] }}>
          {content}
        </View>
      );
    }
  }

  return content;
}
