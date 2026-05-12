import {tutorialGuide} from './tutorialGuide';
import {TutorialSfx, getTutorialInteractions} from './tutorialInteractions';

export const guideMusicTrack = {
  src: 'audio/generated/guide/music/season-1-bed.mp3',
  loop: true
};

export const guideVoiceTracks = tutorialGuide.episodes.map((episode) => ({
  start: episode.time_start,
  end: episode.time_end,
  src: `audio/generated/guide/voice/${episode.id}.mp3`,
  volume: 1
}));

const sfxSourceMap: Record<TutorialSfx, string> = {
  click: 'audio/generated/guide/sfx/click.wav',
  whoosh_soft: 'audio/generated/guide/sfx/whoosh-soft.wav',
  ping: 'audio/generated/guide/sfx/ping.wav'
};

export const guideSfxTracks = tutorialGuide.episodes.flatMap((episode) =>
  getTutorialInteractions(episode.id).map((interaction) => ({
    start: episode.time_start + interaction.at,
    src: sfxSourceMap[interaction.sfx],
    duration: interaction.sfx === 'whoosh_soft' ? 1 : 0.5,
    volume: interaction.sfx === 'click' ? 0.22 : 0.26
  }))
);

export const getGuideMusicLevelAtTime = (timeInSeconds: number) => {
  const currentEpisode = tutorialGuide.episodes.find(
    (episode) => timeInSeconds >= episode.time_start && timeInSeconds < episode.time_end
  );

  if (!currentEpisode) {
    return 0.12;
  }

  if (currentEpisode.scene_type === 'security') {
    return 0.08;
  }

  if (currentEpisode.scene_type === 'closing') {
    return 0.14;
  }

  return 0.1;
};
