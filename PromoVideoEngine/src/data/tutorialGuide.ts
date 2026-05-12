import tutorialGuideJson from './tutorial-guide.json';

export type TutorialEpisode = {
  id: string;
  time_start: number;
  time_end: number;
  episode_label: string;
  scene_type: string;
  headline: string;
  subheadline: string;
  voiceover: string;
  screenshot: string;
  layout: 'image-left' | 'image-right';
  accent_palette: [string, string, string];
  steps: string[];
  capabilities: string[];
};

export type TutorialGuide = {
  video_duration_seconds: number;
  episodes: TutorialEpisode[];
};

export const tutorialGuide = tutorialGuideJson as TutorialGuide;
