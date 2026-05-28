export type InteractionType = 'click' | 'longPress' | 'doubleTap';

export interface NativeDisplayComponentListener {
  getInterestedNodeIds(): Set<string> | null;
  onComponentInteraction(
    nodeId: string,
    interactionType: InteractionType,
    hasServerAction: boolean,
  ): boolean;
}
