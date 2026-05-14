import React, { useEffect, useRef } from 'react';
import { View } from 'react-native';
import { isContainer, isElement } from '../models/NativeDisplayNode';
import { VariableEvaluator } from '../evaluator/VariableEvaluator';
import { useVariables } from '../context/VariablesContext';
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

// Two-step memo pattern: the inner function references the module-level
// `RenderNode` export (the memoized wrapper) when building `sharedProps`.
// Using `export const RenderNode = React.memo(function RenderNode() {...})`
// would make the inner name point to the raw function, not the memoized wrapper.
// Containers would then receive a non-memoized reference and their own
// React.memo checks would never skip a render.
function RenderNodeFn({ node, resolvedStyles, actionHandler }: RenderNodeProps): React.ReactElement | null {
  // Variables come from context rather than being passed as a prop.
  // This lets `RenderNode` be passed by stable reference to containers
  // (no inline closure needed), so container React.memo actually works.
  const variables = useVariables();
  // Keep a stable ref so lifecycle cleanup always sees the current handler
  // without putting actionHandler in the effect's dependency array.
  const actionHandlerRef = useRef(actionHandler);
  actionHandlerRef.current = actionHandler;

  // Lifecycle actions: onAppear fires once on mount, onDisappear fires on unmount.
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
  // Re-run only when the node identity changes (e.g. an item is replaced in a list).
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [node.id]);

  // Check visibility before rendering
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
      // Pass the memoized RenderNode export directly - no inline closure.
      // An inline closure like `(props) => <RenderNode {...props} variables={v} />`
      // is a new function object on every parent render, which looks like a
      // new prop to containers and defeats their React.memo wrapping.
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

  // Wrap in an entrance animation if one is set and it is not 'none'
  if (node.animation && node.animation.type !== 'none') {
    content = <EntranceAnimation animation={node.animation}>{content}</EntranceAnimation>;
  }

  // Wrap in a background renderer if a background is set
  if (resolvedStyle.background) {
    content = (
      <BackgroundRenderer background={resolvedStyle.background}>
        {content}
      </BackgroundRenderer>
    );
  }

  // Apply layout offset for children that are not inside a BOX container.
  // BOX containers clear layout.offset from childForRender after using it as
  // absolute top/left, so this code only runs for VERTICAL/HORIZONTAL/GALLERY children.
  // Percent offsets outside a BOX cannot be resolved without parent dimensions.
  // Matches Android's Modifier.applyOffset() which uses Modifier.offset() (no layout shift).
  const offset = node.layout?.offset;
  if (offset && (offset.x !== 0 || offset.y !== 0)) {
    if (offset.unit === 'percent') {
      console.warn(
        `[RenderNode] node ${node.id}: percent offset outside a BOX container is not supported — use a BOX container for percent-based absolute positioning.`,
      );
    } else {
      // dp / sp / px - shift visually without removing the element from the flex flow
      content = (
        <View style={{ transform: [{ translateX: offset.x }, { translateY: offset.y }] }}>
          {content}
        </View>
      );
    }
  }

  return content;
}

// Memoized export. RenderNodeFn references this module-level binding when
// building `sharedProps.RenderNode`, so containers always receive the stable
// memoized reference rather than the raw inner function.
export const RenderNode = React.memo(RenderNodeFn);
