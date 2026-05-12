import {Easing, interpolate, spring} from 'remotion';

export const clamp01 = (value: number) => Math.min(1, Math.max(0, value));

export const sceneOpacity = (frame: number, durationInFrames: number) => {
  return interpolate(frame, [0, 18, durationInFrames - 18, durationInFrames], [0, 1, 1, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.bezier(0.22, 1, 0.36, 1)
  });
};

export const sceneTranslateY = (frame: number, durationInFrames: number) => {
  const enter = interpolate(frame, [0, 24], [72, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.bezier(0.22, 1, 0.36, 1)
  });

  const exit = interpolate(frame, [durationInFrames - 24, durationInFrames], [0, -52], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.bezier(0.64, 0, 0.78, 0)
  });

  return enter + exit;
};

export const revealScale = (
  frame: number,
  fps: number,
  delay = 0,
  from = 0.86,
  to = 1
) => {
  return interpolate(
    spring({
      fps,
      frame: Math.max(0, frame - delay),
      config: {
        damping: 16,
        stiffness: 150,
        mass: 0.8
      }
    }),
    [0, 1],
    [from, to]
  );
};

export const delayedOpacity = (frame: number, delay: number, duration = 24) => {
  return interpolate(frame, [delay, delay + duration], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.bezier(0.22, 1, 0.36, 1)
  });
};

export const delayedTranslateX = (frame: number, delay: number, from = 60) => {
  return interpolate(frame, [delay, delay + 28], [from, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.bezier(0.22, 1, 0.36, 1)
  });
};

export const delayedTranslateY = (frame: number, delay: number, from = 40) => {
  return interpolate(frame, [delay, delay + 28], [from, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.bezier(0.22, 1, 0.36, 1)
  });
};

export const floatValue = (
  frame: number,
  amplitude: number,
  speed: number,
  phase = 0
) => {
  return Math.sin(frame / speed + phase) * amplitude;
};
