import {Audio, Sequence, staticFile, useVideoConfig} from 'remotion';
import {getGuideMusicLevelAtTime, guideMusicTrack, guideSfxTracks, guideVoiceTracks} from '../data/guideAudio';

export const GuideAudioLayer: React.FC = () => {
  const {fps} = useVideoConfig();

  return (
    <>
      <Audio
        src={staticFile(guideMusicTrack.src)}
        loop={guideMusicTrack.loop}
        volume={(frame) => getGuideMusicLevelAtTime(frame / fps)}
      />

      {guideVoiceTracks.map((track) => (
        <Sequence
          key={track.src}
          from={Math.round(track.start * fps)}
          durationInFrames={Math.max(1, Math.round((track.end - track.start) * fps))}
        >
          <Audio src={staticFile(track.src)} volume={track.volume} />
        </Sequence>
      ))}

      {guideSfxTracks.map((track, index) => (
        <Sequence
          key={`${track.src}-${index}`}
          from={Math.round(track.start * fps)}
          durationInFrames={Math.max(1, Math.round(track.duration * fps))}
        >
          <Audio src={staticFile(track.src)} volume={track.volume} />
        </Sequence>
      ))}
    </>
  );
};
