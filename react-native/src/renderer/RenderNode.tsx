import React from 'react';
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

  return content;
}
