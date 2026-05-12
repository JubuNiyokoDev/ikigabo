import {AbsoluteFill, Img, staticFile, useCurrentFrame, useVideoConfig} from 'remotion';
import {DeviceFrame} from '../components/DeviceFrame';
import {FluidBackground} from '../components/FluidBackground';
import {GlassPanel} from '../components/GlassPanel';
import {SceneShell} from '../components/SceneShell';
import {SectionHeading} from '../components/SectionHeading';
import {promoScreens} from '../data/appManifest';
import {getActiveSceneByType} from '../data/videoScript';
import {delayedOpacity, floatValue} from '../lib/motion';
import {brandTheme} from '../lib/theme';

type UserInteractionSceneProps = {
  durationInFrames: number;
  startFrame: number;
};

const screenOpacity = (
  frame: number,
  from: number,
  holdUntil: number,
  fadeUntil: number
) => {
  if (frame < from) {
    return 0;
  }

  if (frame <= holdUntil) {
    return 1;
  }

  if (frame >= fadeUntil) {
    return 0;
  }

  return 1 - (frame - holdUntil) / (fadeUntil - holdUntil);
};

export const UserInteractionScene: React.FC<UserInteractionSceneProps> = ({
  durationInFrames,
  startFrame
}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const timeInSeconds = (startFrame + frame) / fps;
  const copy = getActiveSceneByType(timeInSeconds, 'emotion');

  const dashboardOpacity = screenOpacity(frame, 0, 52, 74);
  const transactionOpacity = screenOpacity(frame, 54, 112, 132);
  const statsOpacity = screenOpacity(frame, 114, 154, 172);
  const settingsOpacity = frame < 156 ? 0 : Math.min(1, (frame - 156) / 18);

  const pointerX =
    frame < 58
      ? 78
      : frame < 104
        ? 78
        : frame < 140
          ? 52
          : 24;
  const pointerY =
    frame < 58
      ? 86
      : frame < 104
        ? 52 - ((frame - 58) / 46) * 18
        : frame < 140
          ? 32
          : 16;

  const rippleOpacity = frame > 40 && frame < 76 ? 0.4 : frame > 150 ? 0.34 : 0;

  return (
    <SceneShell durationInFrames={durationInFrames}>
      <FluidBackground
        frame={frame}
        palette={[brandTheme.colors.gold, brandTheme.colors.accent, brandTheme.colors.coral]}
      />
      <AbsoluteFill
        style={{
          padding: '98px 112px',
          display: 'flex',
          flexDirection: 'row',
          justifyContent: 'space-between',
          alignItems: 'center'
        }}
      >
        <div
          style={{
            width: 600,
            display: 'flex',
            flexDirection: 'column',
            gap: 28,
            opacity: delayedOpacity(frame, 0, 24)
          }}
        >
          <SectionHeading
            eyebrow="Le Benefice"
            title={copy.on_screen_text}
            body={copy.voiceover}
            maxWidth={560}
          />
          <GlassPanel
            style={{
              width: 470,
              opacity: delayedOpacity(frame, 20, 22),
              transform: `translateY(${floatValue(frame, 8, 52, 0.8)}px)`
            }}
          >
            <div
              style={{
                display: 'grid',
                gridTemplateColumns: 'repeat(3, 1fr)',
                gap: 18
              }}
            >
              {[
                ['01', 'Voir clair'],
                ['02', 'Decider'],
                ['03', 'Avancer']
              ].map(([index, label]) => (
                <div key={index}>
                  <div
                    style={{
                      fontFamily: brandTheme.fonts.mono,
                      fontSize: 16,
                      color: 'rgba(245,251,255,0.58)'
                    }}
                  >
                    {index}
                  </div>
                  <div
                    style={{
                      marginTop: 8,
                      fontFamily: brandTheme.fonts.display,
                      fontSize: 28,
                      fontWeight: 700
                    }}
                  >
                    {label}
                  </div>
                </div>
              ))}
            </div>
          </GlassPanel>
        </div>

        <div
          style={{
            position: 'relative',
            width: 980,
            height: 800
          }}
        >
          <div
            style={{
              position: 'absolute',
              left: 280,
              top: 10
            }}
          >
            <DeviceFrame frame={frame} width={410} rotation={-1}>
              <Img
                src={staticFile(promoScreens.dashboard)}
                style={{
                  position: 'absolute',
                  inset: 0,
                  width: '100%',
                  height: '100%',
                  objectFit: 'cover',
                  opacity: dashboardOpacity
                }}
              />
              <Img
                src={staticFile(promoScreens.transaction)}
                style={{
                  position: 'absolute',
                  inset: 0,
                  width: '100%',
                  height: '100%',
                  objectFit: 'cover',
                  opacity: transactionOpacity
                }}
              />
              <Img
                src={staticFile(promoScreens.stats)}
                style={{
                  position: 'absolute',
                  inset: 0,
                  width: '100%',
                  height: '100%',
                  objectFit: 'cover',
                  opacity: statsOpacity
                }}
              />
              <Img
                src={staticFile(promoScreens.settings)}
                style={{
                  position: 'absolute',
                  inset: 0,
                  width: '100%',
                  height: '100%',
                  objectFit: 'cover',
                  opacity: settingsOpacity
                }}
              />
              <div
                style={{
                  position: 'absolute',
                  left: `${pointerX}%`,
                  top: `${pointerY}%`,
                  width: 34,
                  height: 34,
                  borderRadius: 999,
                  border: '3px solid rgba(255,255,255,0.96)',
                  background: 'rgba(116, 232, 255, 0.24)',
                  boxShadow: '0 0 38px rgba(116, 232, 255, 0.48)',
                  transform: 'translate(-50%, -50%)'
                }}
              />
              <div
                style={{
                  position: 'absolute',
                  left: `${pointerX}%`,
                  top: `${pointerY}%`,
                  width: 90,
                  height: 90,
                  borderRadius: 999,
                  border: '2px solid rgba(255,255,255,0.58)',
                  opacity: rippleOpacity,
                  transform: `translate(-50%, -50%) scale(${1 + floatValue(frame, 0.05, 8)})`
                }}
              />
            </DeviceFrame>
          </div>

          <GlassPanel
            style={{
              position: 'absolute',
              right: 10,
              top: 60,
              width: 260,
              opacity: delayedOpacity(frame, 32, 22)
            }}
          >
            <div
              style={{
                fontFamily: brandTheme.fonts.display,
                fontSize: 30,
                fontWeight: 700
              }}
            >
              Une confiance concrete
            </div>
            <div
              style={{
                marginTop: 12,
                fontFamily: brandTheme.fonts.body,
                fontSize: 18,
                lineHeight: 1.45,
                color: 'rgba(245,251,255,0.74)'
              }}
            >
              Quand vos chiffres sont lisibles, vos choix deviennent plus calmes et plus rapides.
            </div>
          </GlassPanel>

          <GlassPanel
            style={{
              position: 'absolute',
              left: 24,
              bottom: 54,
              width: 280,
              opacity: delayedOpacity(frame, 56, 22)
            }}
          >
            <div
              style={{
                fontFamily: brandTheme.fonts.display,
                fontSize: 30,
                fontWeight: 700
              }}
            >
              Une app qui accompagne
            </div>
            <div
              style={{
                marginTop: 12,
                fontFamily: brandTheme.fonts.body,
                fontSize: 18,
                lineHeight: 1.45,
                color: 'rgba(245,251,255,0.74)'
              }}
            >
              Ikigabo vous aide a suivre, comprendre et proteger ce qui compte vraiment.
            </div>
          </GlassPanel>
        </div>
      </AbsoluteFill>
    </SceneShell>
  );
};
