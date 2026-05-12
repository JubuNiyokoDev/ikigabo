import {AbsoluteFill, Sequence} from 'remotion';
import {GuideAudioLayer} from './components/GuideAudioLayer';
import {brandTheme} from './lib/theme';
import {tutorialGuide} from './data/tutorialGuide';
import {TutorialEpisodeScene} from './scenes/TutorialEpisodeScene';

const fps = 30;

export const guideVideoDurationInFrames = tutorialGuide.video_duration_seconds * fps;

export const GuideVideo: React.FC = () => {
  return (
    <AbsoluteFill
      style={{
        backgroundColor: brandTheme.colors.ink,
        color: brandTheme.colors.paper
      }}
    >
      <GuideAudioLayer />
      {tutorialGuide.episodes.map((episode, index) => {
        const from = Math.round(episode.time_start * fps);
        const durationInFrames = Math.round((episode.time_end - episode.time_start) * fps);
        const nextEpisode = tutorialGuide.episodes[index + 1];

        return (
          <Sequence key={episode.id} from={from} durationInFrames={durationInFrames}>
            <TutorialEpisodeScene
              durationInFrames={durationInFrames}
              episode={episode}
              episodeIndex={index}
              totalEpisodes={tutorialGuide.episodes.length}
              nextEpisodeTitle={nextEpisode?.headline}
            />
          </Sequence>
        );
      })}
    </AbsoluteFill>
  );
};
