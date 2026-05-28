import type { ChildArrangement } from '../models/Layout';
import type { ArrangementStrategy } from '../models/enums';

export interface ArrangementStyle {
  flexDirection: 'row' | 'column';
  justifyContent: 'flex-start' | 'center' | 'flex-end' | 'space-between' | 'space-evenly' | 'space-around';
  gap?: number;
  alignItems: 'flex-start';
}

function strategyToJustifyContent(
  strategy: ArrangementStrategy,
): 'flex-start' | 'center' | 'flex-end' | 'space-between' | 'space-evenly' | 'space-around' {
  switch (strategy) {
    case 'spaced': return 'flex-start';
    case 'space_between': return 'space-between';
    case 'space_evenly': return 'space-evenly';
    case 'space_around': return 'space-around';
    case 'start': return 'flex-start';
    case 'center': return 'center';
    case 'end': return 'flex-end';
    default: return 'flex-start';
  }
}

export function resolveArrangement(
  arrangement: ChildArrangement,
  direction: 'row' | 'column',
): ArrangementStyle {
  const justifyContent = strategyToJustifyContent(arrangement.strategy);
  const style: ArrangementStyle = {
    flexDirection: direction,
    justifyContent,
    alignItems: 'flex-start',
  };

  if (arrangement.strategy === 'spaced' && arrangement.spacing != null && arrangement.spacing > 0) {
    style.gap = arrangement.spacing;
  }

  return style;
}
