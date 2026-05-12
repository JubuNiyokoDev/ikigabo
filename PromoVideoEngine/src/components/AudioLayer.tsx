import {Audio, Sequence, staticFile, useVideoConfig} from 'remotion';
import {getMusicLevelAtTime, promoAudioPlan} from '../data/audioPlan';

export const AudioLayer: React.FC = () => {
  const {fps} = useVideoConfig();
  const {music, voice_over, sfx} = promoAudioPlan.audio_tracks;

  return (
    <>
      {music.enabled ? (
        <Audio
          src={staticFile(music.file)}
          loop={music.loop}
          volume={(frame) => getMusicLevelAtTime(frame / fps)}
        />
      ) : null}

      {voice_over.map((track) => {
        if (!track.enabled) {
          return null;
        }

        return (
          <Sequence
            key={track.asset}
            from={Math.round(track.start * fps)}
            durationInFrames={Math.max(1, Math.round((track.end - track.start) * fps))}
          >
            <Audio src={staticFile(track.asset)} volume={track.volume} />
          </Sequence>
        );
      })}

      {sfx.map((track) => {
        if (!track.enabled) {
          return null;
        }

        return (
          <Sequence
            key={`${track.type}-${track.time}`}
            from={Math.round(track.time * fps)}
            durationInFrames={Math.max(1, Math.round(track.duration * fps))}
          >
            <Audio src={staticFile(track.asset)} volume={track.volume} />
          </Sequence>
        );
      })}
    </>
  );
};
