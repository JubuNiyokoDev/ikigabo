import audioPlanJson from './audio-plan.json';

export type MusicTrack = {
  file: string;
  enabled: boolean;
  loop: boolean;
  default_level: number;
};

export type VoiceOverTrack = {
  start: number;
  end: number;
  text: string;
  asset: string;
  enabled: boolean;
  musicLevel: number;
  volume: number;
};

export type SoundEffectTrack = {
  time: number;
  type: 'click' | 'whoosh' | 'ping' | 'whoosh_soft';
  asset: string;
  enabled: boolean;
  volume: number;
  duration: number;
};

export type AudioPlan = {
  video_duration: number;
  audio_tracks: {
    music: MusicTrack;
    voice_over: VoiceOverTrack[];
    sfx: SoundEffectTrack[];
  };
};

export const promoAudioPlan = audioPlanJson as AudioPlan;

export const getMusicLevelAtTime = (timeInSeconds: number): number => {
  const activeVoiceOver = promoAudioPlan.audio_tracks.voice_over.find(
    (track) => timeInSeconds >= track.start && timeInSeconds < track.end
  );

  return activeVoiceOver?.musicLevel ?? promoAudioPlan.audio_tracks.music.default_level;
};
