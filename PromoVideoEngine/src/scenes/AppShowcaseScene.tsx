import {AbsoluteFill, useCurrentFrame, useVideoConfig} from 'remotion';
import {DeviceFrame} from '../components/DeviceFrame';
import {FluidBackground} from '../components/FluidBackground';
import {GlassPanel} from '../components/GlassPanel';
import {SceneShell} from '../components/SceneShell';
import {SectionHeading} from '../components/SectionHeading';
import {promoScreens} from '../data/appManifest';
import {getActiveSceneByType} from '../data/videoScript';
import {delayedOpacity, delayedTranslateX, floatValue} from '../lib/motion';
import {brandTheme} from '../lib/theme';

type AppShowcaseSceneProps = {
  durationInFrames: number;
  startFrame: number;
};

const labelStyle = {
  fontFamily: brandTheme.fonts.body,
  fontSize: 22,
  fontWeight: 700,
  color: brandTheme.colors.paper
} as const;

export const AppShowcaseScene: React.FC<AppShowcaseSceneProps> = ({
  durationInFrames,
  startFrame
}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const timeInSeconds = (startFrame + frame) / fps;
  const copy = getActiveSceneByType(timeInSeconds, ['problem', 'solution']);
  const supportCards =
    copy.scene_type === 'problem'
      ? [
          {
            title: 'Sources dispersees',
            body: 'Cash, comptes, dettes et actifs vivent souvent dans des coins differents.'
          },
          {
            title: 'Vision incomplete',
            body: 'Quand rien n est centralise, chaque decision demande plus d effort.'
          }
        ]
      : [
          {
            title: 'Tout au meme endroit',
            body: 'Vos mouvements, soldes et priorites restent relies dans une seule vue.'
          },
          {
            title: 'Concu pour le reel',
            body: 'L app prend en compte aussi les biens, les dettes et la vie hors ligne.'
          }
        ];

  const leftOpacity = delayedOpacity(frame, 4, 24);
  const carouselOpacity = delayedOpacity(frame, 18, 30);
  const carouselTranslate = delayedTranslateX(frame, 18, 90);

  return (
    <SceneShell durationInFrames={durationInFrames}>
      <FluidBackground
        frame={frame}
        palette={[brandTheme.colors.accent, brandTheme.colors.gold, brandTheme.colors.mint]}
      />
      <AbsoluteFill
        style={{
          padding: '104px 116px',
          display: 'flex',
          flexDirection: 'row',
          justifyContent: 'space-between',
          alignItems: 'center'
        }}
      >
        <div
          style={{
            opacity: leftOpacity,
            transform: `translateY(${floatValue(frame, 8, 50, 0.6)}px)`
          }}
        >
          <SectionHeading
            eyebrow={copy.scene_type === 'problem' ? 'Le Probleme' : 'La Solution'}
            title={copy.on_screen_text}
            body={copy.voiceover}
            maxWidth={620}
          />
        </div>

        <div
          style={{
            position: 'relative',
            width: 980,
            height: 760,
            opacity: carouselOpacity,
            transform: `translateX(${carouselTranslate}px)`
          }}
        >
          <div
            style={{
              position: 'absolute',
              left: 20,
              top: 110
            }}
          >
            <DeviceFrame
              frame={frame}
              width={290}
              screenSrc={promoScreens.transaction}
              rotation={-12}
              offsetY={34}
              opacity={0.85}
            />
          </div>
          <div
            style={{
              position: 'absolute',
              left: 290,
              top: 10
            }}
          >
            <DeviceFrame
              frame={frame}
              width={380}
              screenSrc={promoScreens.dashboard}
              rotation={-2}
            />
          </div>
          <div
            style={{
              position: 'absolute',
              right: 60,
              top: 120
            }}
          >
            <DeviceFrame
              frame={frame}
              width={290}
              screenSrc={promoScreens.stats}
              rotation={11}
              offsetY={38}
              opacity={0.9}
            />
          </div>

          <GlassPanel
            style={{
              position: 'absolute',
              left: 220,
              bottom: 34,
              width: 250
            }}
          >
            <div style={labelStyle}>{supportCards[0].title}</div>
            <div
              style={{
                marginTop: 10,
                fontFamily: brandTheme.fonts.body,
                fontSize: 18,
                lineHeight: 1.5,
                color: 'rgba(245,251,255,0.74)'
              }}
            >
              {supportCards[0].body}
            </div>
          </GlassPanel>
          <GlassPanel
            style={{
              position: 'absolute',
              right: 4,
              top: 26,
              width: 260
            }}
          >
            <div style={labelStyle}>{supportCards[1].title}</div>
            <div
              style={{
                marginTop: 10,
                fontFamily: brandTheme.fonts.body,
                fontSize: 18,
                lineHeight: 1.5,
                color: 'rgba(245,251,255,0.74)'
              }}
            >
              {supportCards[1].body}
            </div>
          </GlassPanel>
        </div>
      </AbsoluteFill>
    </SceneShell>
  );
};
