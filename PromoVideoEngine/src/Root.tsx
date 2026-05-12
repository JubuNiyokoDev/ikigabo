import {Composition} from 'remotion';
import {GuideVideo, guideVideoDurationInFrames} from './GuideVideo';
import {PromoVideo, promoVideoDurationInFrames} from './PromoVideo';

export const Root: React.FC = () => {
  return (
    <>
      <Composition
        id="PromoVideo"
        component={PromoVideo}
        durationInFrames={promoVideoDurationInFrames}
        fps={30}
        width={1920}
        height={1080}
      />
      <Composition
        id="IkigaboFullGuide"
        component={GuideVideo}
        durationInFrames={guideVideoDurationInFrames}
        fps={30}
        width={1920}
        height={1080}
      />
    </>
  );
};
