import {AbsoluteFill, Img, staticFile, useCurrentFrame, useVideoConfig} from 'remotion';
import {DeviceFrame} from '../components/DeviceFrame';
import {FluidBackground} from '../components/FluidBackground';
import {GlassPanel} from '../components/GlassPanel';
import {SceneShell} from '../components/SceneShell';
import {appBrand, promoScreens} from '../data/appManifest';
import {getActiveSceneByType} from '../data/videoScript';
import {delayedOpacity, delayedTranslateY, revealScale} from '../lib/motion';
import {brandTheme} from '../lib/theme';

type OutroSceneProps = {
  durationInFrames: number;
  startFrame: number;
};

export const OutroScene: React.FC<OutroSceneProps> = ({durationInFrames, startFrame}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const timeInSeconds = (startFrame + frame) / fps;
  const copy = getActiveSceneByType(timeInSeconds, 'call_to_action');

  return (
    <SceneShell durationInFrames={durationInFrames}>
      <FluidBackground
        frame={frame}
        palette={[brandTheme.colors.coral, brandTheme.colors.accent, brandTheme.colors.mint]}
      />
      <AbsoluteFill
        style={{
          padding: '104px 120px',
          display: 'flex',
          flexDirection: 'row',
          justifyContent: 'space-between',
          alignItems: 'center'
        }}
      >
        <div
          style={{
            width: 760,
            display: 'flex',
            flexDirection: 'column',
            gap: 26,
            opacity: delayedOpacity(frame, 0, 24),
            transform: `translateY(${delayedTranslateY(frame, 0, 40)}px)`
          }}
        >
          <div
            style={{
              width: 112,
              height: 112,
              borderRadius: 32,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              background:
                'linear-gradient(180deg, rgba(255,255,255,0.18) 0%, rgba(255,255,255,0.05) 100%)',
              border: '1px solid rgba(255,255,255,0.16)',
              transform: `scale(${revealScale(frame, fps, 0, 0.74, 1)})`
            }}
          >
            <Img
              src={staticFile(appBrand.logoSrc)}
              style={{
                width: 76,
                height: 76,
                objectFit: 'contain'
              }}
            />
          </div>

          <div
            style={{
              fontFamily: brandTheme.fonts.display,
              fontSize: 104,
              lineHeight: 0.94,
              letterSpacing: '-0.06em',
              fontWeight: 700
            }}
          >
            {copy.on_screen_text}
          </div>

          <div
            style={{
              fontFamily: brandTheme.fonts.body,
              fontSize: 30,
              lineHeight: 1.45,
              color: 'rgba(245,251,255,0.78)'
            }}
          >
            {copy.voiceover}
          </div>

          <GlassPanel
            style={{
              width: 420,
              marginTop: 10
            }}
          >
            <div
              style={{
                fontFamily: brandTheme.fonts.body,
                fontSize: 18,
                letterSpacing: '0.24em',
                textTransform: 'uppercase',
                color: 'rgba(245,251,255,0.64)'
              }}
            >
              Google Play
            </div>
            <div
              style={{
                marginTop: 10,
                fontFamily: brandTheme.fonts.display,
                fontSize: 38,
                fontWeight: 700
              }}
            >
              {appBrand.cta}
            </div>
            <div
              style={{
                marginTop: 10,
                fontFamily: brandTheme.fonts.body,
                fontSize: 18,
                lineHeight: 1.45,
                color: 'rgba(245,251,255,0.7)'
              }}
            >
              {appBrand.ctaSupport}
            </div>
          </GlassPanel>
        </div>

        <div
          style={{
            position: 'relative',
            width: 760,
            height: 780
          }}
        >
          <div
            style={{
              position: 'absolute',
              right: 270,
              top: 26,
              opacity: 0.54
            }}
          >
            <DeviceFrame
              frame={frame}
              width={270}
              screenSrc={promoScreens.dashboard}
              rotation={-16}
              offsetY={38}
            />
          </div>
          <div
            style={{
              position: 'absolute',
              right: 124,
              top: 46
            }}
          >
            <DeviceFrame frame={frame} width={340} screenSrc={promoScreens.stats} rotation={2} />
          </div>
          <div
            style={{
              position: 'absolute',
              right: 16,
              top: 120,
              opacity: 0.76
            }}
          >
            <DeviceFrame
              frame={frame}
              width={270}
              screenSrc={promoScreens.settings}
              rotation={16}
              offsetY={30}
            />
          </div>
        </div>
      </AbsoluteFill>
    </SceneShell>
  );
};
