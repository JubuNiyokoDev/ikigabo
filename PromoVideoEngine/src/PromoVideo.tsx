import {AbsoluteFill, Sequence} from 'remotion';
import {AudioLayer} from './components/AudioLayer';
import {promoVideoScript} from './data/videoScript';
import {brandTheme} from './lib/theme';
import {AppShowcaseScene} from './scenes/AppShowcaseScene';
import {FeatureHighlightScene} from './scenes/FeatureHighlightScene';
import {IntroScene} from './scenes/IntroScene';
import {OutroScene} from './scenes/OutroScene';
import {UserInteractionScene} from './scenes/UserInteractionScene';

const fps = 30;

const sceneDurations = {
  intro: 5 * fps,
  showcase: 45 * fps,
  features: 40 * fps,
  interaction: 20 * fps,
  outro: 10 * fps
};

const showcaseFrom = sceneDurations.intro;
const featuresFrom = showcaseFrom + sceneDurations.showcase;
const interactionFrom = featuresFrom + sceneDurations.features;
const outroFrom = interactionFrom + sceneDurations.interaction;

export const promoVideoDurationInFrames = promoVideoScript.video_duration_seconds * fps;

export const PromoVideo: React.FC = () => {
  return (
    <AbsoluteFill
      style={{
        backgroundColor: brandTheme.colors.ink,
        color: brandTheme.colors.paper
      }}
    >
      <AudioLayer />
      <Sequence from={0} durationInFrames={sceneDurations.intro}>
        <IntroScene durationInFrames={sceneDurations.intro} startFrame={0} />
      </Sequence>
      <Sequence from={showcaseFrom} durationInFrames={sceneDurations.showcase}>
        <AppShowcaseScene
          durationInFrames={sceneDurations.showcase}
          startFrame={showcaseFrom}
        />
      </Sequence>
      <Sequence from={featuresFrom} durationInFrames={sceneDurations.features}>
        <FeatureHighlightScene
          durationInFrames={sceneDurations.features}
          startFrame={featuresFrom}
        />
      </Sequence>
      <Sequence from={interactionFrom} durationInFrames={sceneDurations.interaction}>
        <UserInteractionScene
          durationInFrames={sceneDurations.interaction}
          startFrame={interactionFrom}
        />
      </Sequence>
      <Sequence from={outroFrom} durationInFrames={sceneDurations.outro}>
        <OutroScene durationInFrames={sceneDurations.outro} startFrame={outroFrom} />
      </Sequence>
    </AbsoluteFill>
  );
};
