import type {PropsWithChildren} from 'react';
import {Img, staticFile} from 'remotion';
import {floatValue} from '../lib/motion';

type DeviceFrameProps = PropsWithChildren<{
  frame: number;
  screenSrc?: string;
  width?: number;
  rotation?: number;
  offsetY?: number;
  opacity?: number;
}>;

export const DeviceFrame: React.FC<DeviceFrameProps> = ({
  children,
  frame,
  screenSrc,
  width = 360,
  rotation = 0,
  offsetY = 0,
  opacity = 1
}) => {
  const levitate = floatValue(frame, 18, 34, width / 100) + offsetY;
  const tilt = rotation + floatValue(frame, 1.6, 44, width / 180);

  return (
    <div
      style={{
        position: 'relative',
        width,
        aspectRatio: '1080 / 2400',
        borderRadius: 58,
        padding: 16,
        background: 'linear-gradient(180deg, #0F1014 0%, #040608 100%)',
        boxShadow:
          '0 56px 120px rgba(0, 0, 0, 0.5), inset 0 1px 0 rgba(255,255,255,0.15)',
        opacity,
        transform: `translateY(${levitate}px) rotate(${tilt}deg)`
      }}
    >
      <div
        style={{
          position: 'absolute',
          top: 12,
          left: '50%',
          width: width * 0.28,
          height: 26,
          borderRadius: 999,
          background: '#050608',
          transform: 'translateX(-50%)',
          zIndex: 3
        }}
      />
      <div
        style={{
          position: 'relative',
          width: '100%',
          height: '100%',
          overflow: 'hidden',
          borderRadius: 44,
          background: '#081420'
        }}
      >
        {screenSrc ? (
          <Img
            src={staticFile(screenSrc)}
            style={{
              width: '100%',
              height: '100%',
              objectFit: 'cover'
            }}
          />
        ) : null}
        {children ? (
          <div
            style={{
              position: 'absolute',
              inset: 0
            }}
          >
            {children}
          </div>
        ) : null}
        <div
          style={{
            position: 'absolute',
            inset: 0,
            background:
              'linear-gradient(180deg, rgba(255,255,255,0.12) 0%, transparent 14%, transparent 70%, rgba(255,255,255,0.05) 100%)'
          }}
        />
        <div
          style={{
            position: 'absolute',
            inset: 0,
            background:
              'linear-gradient(108deg, rgba(255,255,255,0.18) 0%, transparent 20%, transparent 74%, rgba(255,255,255,0.08) 100%)'
          }}
        />
      </div>
    </div>
  );
};
