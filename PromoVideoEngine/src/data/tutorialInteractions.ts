import tutorialInteractionsJson from './tutorial-interactions.json';

export type TutorialGesture = 'tap' | 'swipe' | 'focus';
export type TutorialSfx = 'click' | 'whoosh_soft' | 'ping';
export type TutorialSide = 'left' | 'right';

export type TutorialInteraction = {
  step_index: number;
  at: number;
  duration: number;
  target: string;
  x: number;
  y: number;
  to_x?: number;
  to_y?: number;
  gesture: TutorialGesture;
  sfx: TutorialSfx;
  side: TutorialSide;
};

export const tutorialInteractions = tutorialInteractionsJson as Record<
  string,
  TutorialInteraction[]
>;

export const getTutorialInteractions = (episodeId: string): TutorialInteraction[] => {
  return tutorialInteractions[episodeId] ?? [];
};
