import {AbsoluteFill, useCurrentFrame, useVideoConfig} from 'remotion';
import {DeviceFrame} from '../components/DeviceFrame';
import {FluidBackground} from '../components/FluidBackground';
import {GlassPanel} from '../components/GlassPanel';
import {SceneShell} from '../components/SceneShell';
import {SectionHeading} from '../components/SectionHeading';
import {promoFeatures, promoScreens} from '../data/appManifest';
import {getActiveSceneByType} from '../data/videoScript';
import {
  delayedOpacity,
  delayedTranslateX,
  delayedTranslateY,
  floatValue
} from '../lib/motion';
import {brandTheme} from '../lib/theme';

type FeatureHighlightSceneProps = {
  durationInFrames: number;
  startFrame: number;
};

export const FeatureHighlightScene: React.FC<FeatureHighlightSceneProps> = ({
  durationInFrames,
  startFrame
}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const timeInSeconds = (startFrame + frame) / fps;
  const copy = getActiveSceneByType(timeInSeconds, 'feature');

  return (
    <SceneShell durationInFrames={durationInFrames}>
      <FluidBackground
        frame={frame}
        palette={[brandTheme.colors.mint, brandTheme.colors.accent, brandTheme.colors.coral]}
      />
      <AbsoluteFill
        style={{
          padding: '96px 110px',
          display: 'flex',
          flexDirection: 'row',
          justifyContent: 'space-between',
          alignItems: 'center'
        }}
      >
        <div
          style={{
            width: 620,
            display: 'flex',
            flexDirection: 'column',
            gap: 28,
            opacity: delayedOpacity(frame, 0, 24)
          }}
        >
          <SectionHeading
            eyebrow="Fonctionnalites"
            title={copy.on_screen_text}
            body={copy.voiceover}
            maxWidth={580}
          />
          <div
            style={{
              display: 'flex',
              gap: 14,
              flexWrap: 'wrap'
            }}
          >
            {['Dashboard', 'Transactions', 'Actifs reels', 'Securite'].map((item, index) => (
              <div
                key={item}
                style={{
                  padding: '14px 18px',
                  borderRadius: 999,
                  background: 'rgba(255,255,255,0.08)',
                  border: '1px solid rgba(255,255,255,0.14)',
                  fontFamily: brandTheme.fonts.body,
                  fontSize: 18,
                  fontWeight: 700,
                  color: 'rgba(245,251,255,0.86)',
                  opacity: delayedOpacity(frame, 10 + index * 6, 18),
                  transform: `translateY(${delayedTranslateY(frame, 10 + index * 6, 20)}px)`
                }}
              >
                {item}
              </div>
            ))}
          </div>
        </div>

        <div
          style={{
            position: 'relative',
            width: 980,
            height: 780
          }}
        >
          <div
            style={{
              position: 'absolute',
              left: 295,
              top: 92,
              transform: `translateY(${floatValue(frame, 10, 50, 0.4)}px)`
            }}
          >
            <DeviceFrame frame={frame} width={390} screenSrc={promoScreens.stats} rotation={2} />
          </div>

          {promoFeatures.map((feature, index) => {
            const placements = [
              {left: 20, top: 40, delay: 10, x: -60, y: 26},
              {left: 0, top: 500, delay: 18, x: -70, y: 34},
              {right: 30, top: 70, delay: 26, x: 64, y: 28},
              {right: 0, top: 520, delay: 34, x: 74, y: 34}
            ] as const;
            const placement = placements[index];

            return (
              <GlassPanel
                key={feature.title}
                style={{
                  position: 'absolute',
                  width: 270,
                  ...placement,
                  opacity: delayedOpacity(frame, placement.delay, 26),
                  transform: `translate(${delayedTranslateX(frame, placement.delay, placement.x)}px, ${delayedTranslateY(frame, placement.delay, placement.y)}px)`
                }}
              >
                <div
                  style={{
                    width: 18,
                    height: 18,
                    borderRadius: 999,
                    background: feature.accent,
                    boxShadow: `0 0 28px ${feature.accent}`
                  }}
                />
                <div
                  style={{
                    marginTop: 16,
                    fontFamily: brandTheme.fonts.display,
                    fontSize: 34,
                    lineHeight: 1.06,
                    fontWeight: 700
                  }}
                >
                  {feature.title}
                </div>
                <div
                  style={{
                    marginTop: 14,
                    fontFamily: brandTheme.fonts.body,
                    fontSize: 19,
                    lineHeight: 1.45,
                    color: 'rgba(245,251,255,0.76)'
                  }}
                >
                  {feature.body}
                </div>
              </GlassPanel>
            );
          })}
        </div>
      </AbsoluteFill>
    </SceneShell>
  );
};
