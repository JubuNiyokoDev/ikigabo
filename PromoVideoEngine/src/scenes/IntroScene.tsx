import {AbsoluteFill, Img, staticFile, useCurrentFrame, useVideoConfig} from 'remotion';
import {DeviceFrame} from '../components/DeviceFrame';
import {FluidBackground} from '../components/FluidBackground';
import {SceneShell} from '../components/SceneShell';
import {appBrand, promoScreens} from '../data/appManifest';
import {getActiveSceneByType} from '../data/videoScript';
import {delayedOpacity, delayedTranslateX, delayedTranslateY, revealScale} from '../lib/motion';
import {brandTheme} from '../lib/theme';

type IntroSceneProps = {
  durationInFrames: number;
  startFrame: number;
};

export const IntroScene: React.FC<IntroSceneProps> = ({durationInFrames, startFrame}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const timeInSeconds = (startFrame + frame) / fps;
  const copy = getActiveSceneByType(timeInSeconds, 'hook');

  const logoScale = revealScale(frame, fps, 0, 0.6, 1);
  const leftOpacity = delayedOpacity(frame, 6, 26);
  const leftTranslate = delayedTranslateY(frame, 6, 42);
  const deviceOpacity = delayedOpacity(frame, 18, 30);
  const deviceTranslate = delayedTranslateX(frame, 18, 80);

  return (
    <SceneShell durationInFrames={durationInFrames}>
      <FluidBackground
        frame={frame}
        palette={[brandTheme.colors.accent, brandTheme.colors.mint, brandTheme.colors.gold]}
      />
      <AbsoluteFill
        style={{
          padding: '110px 120px',
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
            gap: 30,
            opacity: leftOpacity,
            transform: `translateY(${leftTranslate}px)`
          }}
        >
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: 22
            }}
          >
            <div
              style={{
                width: 126,
                height: 126,
                borderRadius: 32,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                background:
                  'linear-gradient(180deg, rgba(255,255,255,0.18) 0%, rgba(255,255,255,0.05) 100%)',
                border: '1px solid rgba(255,255,255,0.18)',
                boxShadow: '0 30px 80px rgba(0, 0, 0, 0.28)',
                transform: `scale(${logoScale})`
              }}
            >
              <Img
                src={staticFile(appBrand.logoSrc)}
                style={{
                  width: 86,
                  height: 86,
                  objectFit: 'contain'
                }}
              />
            </div>
            <div
              style={{
                padding: '14px 18px',
                borderRadius: 999,
                border: '1px solid rgba(255,255,255,0.16)',
                background: 'rgba(255,255,255,0.08)',
                fontFamily: brandTheme.fonts.body,
                letterSpacing: '0.24em',
                textTransform: 'uppercase',
                fontSize: 18,
                fontWeight: 700,
                color: 'rgba(245, 251, 255, 0.78)'
              }}
            >
              {appBrand.categoryBadge}
            </div>
          </div>
          <div
            style={{
              fontFamily: brandTheme.fonts.display,
              fontSize: 118,
              lineHeight: 0.92,
              letterSpacing: '-0.06em',
              fontWeight: 700
            }}
          >
            {appBrand.name}
          </div>
          <div
            style={{
              fontFamily: brandTheme.fonts.body,
              fontSize: 42,
              lineHeight: 1.4,
              color: 'rgba(245, 251, 255, 0.82)'
            }}
          >
            {copy.on_screen_text}
          </div>
          <div
            style={{
              fontFamily: brandTheme.fonts.body,
              fontSize: 26,
              lineHeight: 1.5,
              color: 'rgba(245, 251, 255, 0.66)'
            }}
          >
            {copy.voiceover}
          </div>
          <div
            style={{
              fontFamily: brandTheme.fonts.body,
              fontSize: 22,
              lineHeight: 1.5,
              color: 'rgba(245, 251, 255, 0.56)'
            }}
          >
            {appBrand.subline}
          </div>
        </div>

        <div
          style={{
            position: 'relative',
            width: 760,
            height: 800,
            opacity: deviceOpacity,
            transform: `translateX(${deviceTranslate}px)`
          }}
        >
          <div
            style={{
              position: 'absolute',
              right: 30,
              bottom: 10,
              opacity: 0.48
            }}
          >
            <DeviceFrame
              frame={frame}
              width={300}
              screenSrc={promoScreens.onboarding2}
              rotation={12}
              offsetY={36}
            />
          </div>
          <div
            style={{
              position: 'absolute',
              right: 250,
              top: 40
            }}
          >
            <DeviceFrame
              frame={frame}
              width={410}
              screenSrc={promoScreens.dashboard}
              rotation={-7}
            />
          </div>
          <div
            style={{
              position: 'absolute',
              right: 80,
              top: 170,
              opacity: 0.78
            }}
          >
            <DeviceFrame
              frame={frame}
              width={280}
              screenSrc={promoScreens.onboarding1}
              rotation={8}
              offsetY={20}
            />
          </div>
        </div>
      </AbsoluteFill>
    </SceneShell>
  );
};
