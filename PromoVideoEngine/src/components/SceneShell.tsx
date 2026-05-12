import type {PropsWithChildren} from 'react';
import {AbsoluteFill, useCurrentFrame} from 'remotion';
import {sceneOpacity, sceneTranslateY} from '../lib/motion';

type SceneShellProps = PropsWithChildren<{
  durationInFrames: number;
}>;

export const SceneShell: React.FC<SceneShellProps> = ({children, durationInFrames}) => {
  const frame = useCurrentFrame();
  const opacity = sceneOpacity(frame, durationInFrames);
  const translateY = sceneTranslateY(frame, durationInFrames);

  return (
    <AbsoluteFill
      style={{
        opacity,
        transform: `translateY(${translateY}px)`
      }}
    >
      {children}
    </AbsoluteFill>
  );
};
