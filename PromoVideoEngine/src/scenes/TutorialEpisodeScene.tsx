import {AbsoluteFill, useCurrentFrame, useVideoConfig} from 'remotion';
import {FluidBackground} from '../components/FluidBackground';
import {GlassPanel} from '../components/GlassPanel';
import {SceneShell} from '../components/SceneShell';
import {TutorialScreenOverlay} from '../components/TutorialScreenOverlay';
import {TutorialEpisode} from '../data/tutorialGuide';
import {getTutorialInteractions} from '../data/tutorialInteractions';
import {
  delayedOpacity,
  delayedTranslateX,
  delayedTranslateY,
  floatValue
} from '../lib/motion';
import {brandTheme} from '../lib/theme';

type TutorialEpisodeSceneProps = {
  durationInFrames: number;
  episode: TutorialEpisode;
  episodeIndex: number;
  totalEpisodes: number;
  nextEpisodeTitle?: string;
};

export const TutorialEpisodeScene: React.FC<TutorialEpisodeSceneProps> = ({
  durationInFrames,
  episode,
  episodeIndex,
  totalEpisodes,
  nextEpisodeTitle
}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const localTime = frame / fps;
  const interactions = getTutorialInteractions(episode.id);
  const activeInteractionIndex = interactions.findIndex(
    (interaction) => localTime >= interaction.at && localTime < interaction.at + interaction.duration
  );
  const activeStepIndex =
    activeInteractionIndex >= 0
      ? activeInteractionIndex
      : interactions.reduce((accumulator, interaction, index) => {
          return localTime >= interaction.at ? index : accumulator;
        }, 0);
  const textOpacity = delayedOpacity(frame, 0, 24);
  const mediaOpacity = delayedOpacity(frame, 10, 26);
  const mediaTranslate = delayedTranslateX(
    frame,
    10,
    episode.layout === 'image-left' ? -60 : 60
  );

  const screenshotPanel = (
    <div
      style={{
        width: 760,
        height: 880,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        opacity: mediaOpacity,
        transform: `translateX(${mediaTranslate}px) translateY(${floatValue(frame, 10, 70, 0.5)}px)`
      }}
    >
      <GlassPanel
        style={{
          width: '100%',
          height: '100%',
          padding: 24,
          display: 'flex',
          flexDirection: 'column',
          gap: 18,
          alignItems: 'center'
        }}
      >
        <div
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center'
          }}
        >
          <div
            style={{
              padding: '10px 14px',
              borderRadius: 999,
              background: 'rgba(255,255,255,0.08)',
              border: '1px solid rgba(255,255,255,0.12)',
              fontFamily: brandTheme.fonts.body,
              fontSize: 16,
              letterSpacing: '0.18em',
              textTransform: 'uppercase',
              color: 'rgba(245,251,255,0.7)'
            }}
          >
            Capture complete
          </div>
          <div
            style={{
              fontFamily: brandTheme.fonts.mono,
              fontSize: 16,
              color: 'rgba(245,251,255,0.58)'
            }}
          >
            {episode.episode_label} / {totalEpisodes}
          </div>
        </div>

        <div
          style={{
            flex: 1,
            borderRadius: 28,
            overflow: 'hidden',
            background: 'rgba(3, 19, 31, 0.7)',
            border: '1px solid rgba(255,255,255,0.08)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            width: '100%'
          }}
        >
          <TutorialScreenOverlay
            screenshot={episode.screenshot}
            interactions={interactions}
            steps={episode.steps}
            accentPalette={episode.accent_palette}
          />
        </div>
      </GlassPanel>
    </div>
  );

  const textPanel = (
    <div
      style={{
        width: 780,
        display: 'flex',
        flexDirection: 'column',
        gap: 22,
        opacity: textOpacity,
        transform: `translateY(${delayedTranslateY(frame, 0, 30)}px)`
      }}
    >
      <div
        style={{
          display: 'flex',
          gap: 14,
          alignItems: 'center',
          flexWrap: 'wrap'
        }}
      >
        <div
          style={{
            padding: '10px 16px',
            borderRadius: 999,
            background: 'rgba(255,255,255,0.08)',
            border: '1px solid rgba(255,255,255,0.14)',
            fontFamily: brandTheme.fonts.body,
            fontSize: 18,
            fontWeight: 700,
            letterSpacing: '0.2em',
            textTransform: 'uppercase',
            color: 'rgba(245,251,255,0.78)'
          }}
        >
          {episode.episode_label}
        </div>
        <div
          style={{
            padding: '10px 16px',
            borderRadius: 999,
            background: 'rgba(255,255,255,0.06)',
            border: '1px solid rgba(255,255,255,0.1)',
            fontFamily: brandTheme.fonts.body,
            fontSize: 16,
            fontWeight: 600,
            color: 'rgba(245,251,255,0.62)'
          }}
        >
          Chapitre {episodeIndex + 1} sur {totalEpisodes}
        </div>
      </div>

      <div
        style={{
          fontFamily: brandTheme.fonts.display,
          fontSize: 76,
          lineHeight: 0.98,
          letterSpacing: '-0.05em',
          fontWeight: 700
        }}
      >
        {episode.headline}
      </div>

      <div
        style={{
          fontFamily: brandTheme.fonts.body,
          fontSize: 28,
          lineHeight: 1.4,
          color: 'rgba(245,251,255,0.82)'
        }}
      >
        {episode.subheadline}
      </div>

      <GlassPanel
        style={{
          padding: '24px 28px'
        }}
      >
        <div
          style={{
            fontFamily: brandTheme.fonts.body,
            fontSize: 22,
            lineHeight: 1.65,
            color: 'rgba(245,251,255,0.78)'
          }}
        >
          {episode.voiceover}
        </div>
      </GlassPanel>

      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(2, minmax(0, 1fr))',
          gap: 16
        }}
      >
        {episode.steps.map((step, index) => (
          <GlassPanel
            key={step}
            style={{
              minHeight: 138,
              padding: '20px 22px',
              opacity: delayedOpacity(frame, 8 + index * 5, 18),
              transform: `translateY(${delayedTranslateY(frame, 8 + index * 5, 18)}px)`,
              border:
                index === activeStepIndex
                  ? `1px solid ${episode.accent_palette[index % episode.accent_palette.length]}`
                  : undefined,
              boxShadow:
                index === activeStepIndex
                  ? `0 20px 50px ${episode.accent_palette[index % episode.accent_palette.length]}22`
                  : undefined
            }}
          >
            <div
              style={{
                fontFamily: brandTheme.fonts.mono,
                fontSize: 16,
                color: episode.accent_palette[index % episode.accent_palette.length]
              }}
            >
              ETAPE {index + 1}
            </div>
            <div
              style={{
                marginTop: 10,
                fontFamily: brandTheme.fonts.body,
                fontSize: 18,
                lineHeight: 1.55,
                color: 'rgba(245,251,255,0.8)'
              }}
            >
              {step}
            </div>
            {interactions[index] ? (
              <div
                style={{
                  marginTop: 10,
                  fontFamily: brandTheme.fonts.body,
                  fontSize: 14,
                  lineHeight: 1.45,
                  color: 'rgba(245,251,255,0.56)'
                }}
              >
                Cible: {interactions[index].target}
              </div>
            ) : null}
          </GlassPanel>
        ))}
      </div>

      <div
        style={{
          display: 'flex',
          gap: 12,
          flexWrap: 'wrap'
        }}
      >
        {episode.capabilities.map((capability, index) => (
          <div
            key={capability}
            style={{
              padding: '12px 16px',
              borderRadius: 999,
              background: 'rgba(255,255,255,0.08)',
              border: '1px solid rgba(255,255,255,0.12)',
              fontFamily: brandTheme.fonts.body,
              fontSize: 16,
              fontWeight: 700,
              color: episode.accent_palette[index % episode.accent_palette.length],
              opacity: delayedOpacity(frame, 16 + index * 4, 18)
            }}
          >
            {capability}
          </div>
        ))}
      </div>

      <div
        style={{
          marginTop: 2,
          fontFamily: brandTheme.fonts.body,
          fontSize: 20,
          color: 'rgba(245,251,255,0.58)'
        }}
      >
        {nextEpisodeTitle ? `Suivant: ${nextEpisodeTitle}` : 'Fin du guide'}
      </div>
    </div>
  );

  return (
    <SceneShell durationInFrames={durationInFrames}>
      <FluidBackground frame={frame} palette={episode.accent_palette} />
      <AbsoluteFill
        style={{
          padding: '90px 92px',
          display: 'flex',
          flexDirection: episode.layout === 'image-left' ? 'row' : 'row-reverse',
          justifyContent: 'space-between',
          alignItems: 'center',
          gap: 40
        }}
      >
        {screenshotPanel}
        {textPanel}
      </AbsoluteFill>
    </SceneShell>
  );
};
