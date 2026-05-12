import type {CSSProperties} from 'react';
import {Img, interpolate, staticFile, useCurrentFrame, useVideoConfig} from 'remotion';
import {TutorialInteraction} from '../data/tutorialInteractions';
import {brandTheme} from '../lib/theme';

type TutorialScreenOverlayProps = {
  screenshot: string;
  interactions: TutorialInteraction[];
  steps: string[];
  accentPalette: [string, string, string];
};

const clamp = (value: number, min: number, max: number) => Math.min(max, Math.max(min, value));

const calloutPosition = (
  step: TutorialInteraction,
  screenWidth: number,
  screenHeight: number
): CSSProperties => {
  const x = step.x * screenWidth;
  const y = step.y * screenHeight;
  const toRight = step.side === 'right';

  return {
    position: 'absolute',
    left: toRight ? clamp(x + 36, 24, screenWidth - 300) : undefined,
    right: toRight ? undefined : clamp(screenWidth - x + 36, 24, screenWidth - 300),
    top: clamp(y - 48, 24, screenHeight - 140),
    width: 280
  };
};

export const TutorialScreenOverlay: React.FC<TutorialScreenOverlayProps> = ({
  screenshot,
  interactions,
  steps,
  accentPalette
}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const localTime = frame / fps;
  const screenWidth = 372;
  const screenHeight = 826;

  const activeIndex = interactions.findIndex(
    (step) => localTime >= step.at && localTime < step.at + step.duration
  );
  const safeIndex =
    activeIndex >= 0
      ? activeIndex
      : interactions.reduce((accumulator, step, index) => {
          return localTime >= step.at ? index : accumulator;
        }, 0);
  const activeStep = interactions[safeIndex];

  const progress = activeStep
    ? clamp((localTime - activeStep.at) / Math.max(activeStep.duration, 0.001), 0, 1)
    : 0;

  const cursorX = activeStep
    ? interpolate(progress, [0, 1], [activeStep.x, activeStep.to_x ?? activeStep.x])
    : 0.5;
  const cursorY = activeStep
    ? interpolate(progress, [0, 1], [activeStep.y, activeStep.to_y ?? activeStep.y])
    : 0.5;

  return (
    <div
      style={{
        position: 'relative',
        width: screenWidth,
        height: screenHeight,
        borderRadius: 42,
        overflow: 'hidden',
        background: '#081420',
        border: '1px solid rgba(255,255,255,0.12)',
        boxShadow:
          '0 40px 100px rgba(0,0,0,0.45), inset 0 1px 0 rgba(255,255,255,0.12)'
      }}
    >
      <Img
        src={staticFile(screenshot)}
        style={{
          width: '100%',
          height: '100%',
          objectFit: 'cover'
        }}
      />

      <div
        style={{
          position: 'absolute',
          inset: 0,
          background:
            'linear-gradient(180deg, rgba(255,255,255,0.08) 0%, transparent 18%, transparent 72%, rgba(0,0,0,0.12) 100%)'
        }}
      />

      {interactions.map((step, index) => {
        const isActive = index === safeIndex;
        const x = step.x * screenWidth;
        const y = step.y * screenHeight;
        const color = accentPalette[index % accentPalette.length];

        return (
          <div key={`${step.target}-${step.step_index}`}>
            {step.gesture === 'swipe' && step.to_x !== undefined && step.to_y !== undefined ? (
              <div
                style={{
                  position: 'absolute',
                  left: Math.min(step.x, step.to_x) * screenWidth,
                  top: Math.min(step.y, step.to_y) * screenHeight,
                  width: Math.max(Math.abs(step.to_x - step.x) * screenWidth, 3),
                  height: Math.max(Math.abs(step.to_y - step.y) * screenHeight, 3),
                  borderTop: `2px dashed ${isActive ? color : 'rgba(255,255,255,0.18)'}`,
                  opacity: isActive ? 0.95 : 0.36,
                  transformOrigin: 'top left',
                  transform: `rotate(${Math.atan2(
                    (step.to_y - step.y) * screenHeight,
                    (step.to_x - step.x) * screenWidth
                  )}rad)`
                }}
              />
            ) : null}

            <div
              style={{
                position: 'absolute',
                left: x - 18,
                top: y - 18,
                width: 36,
                height: 36,
                borderRadius: 999,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontFamily: brandTheme.fonts.body,
                fontSize: 16,
                fontWeight: 800,
                color: '#03131F',
                background: isActive ? color : 'rgba(255,255,255,0.72)',
                boxShadow: isActive ? `0 0 30px ${color}` : '0 10px 24px rgba(0,0,0,0.18)',
                opacity: isActive ? 1 : 0.68
              }}
            >
              {index + 1}
            </div>

            <div
              style={{
                position: 'absolute',
                left: x - 34,
                top: y - 34,
                width: 68,
                height: 68,
                borderRadius: 999,
                border: `2px solid ${isActive ? color : 'rgba(255,255,255,0.18)'}`,
                opacity: isActive ? 0.82 : 0.28,
                transform: `scale(${isActive ? 1 + Math.sin(frame / 7) * 0.08 : 1})`
              }}
            />
          </div>
        );
      })}

      {activeStep ? (
        <>
          <div
            style={{
              position: 'absolute',
              left: cursorX * screenWidth - 20,
              top: cursorY * screenHeight - 20,
              width: 40,
              height: 40,
              borderRadius: 999,
              border: '3px solid rgba(255,255,255,0.96)',
              background: 'rgba(116,232,255,0.2)',
              boxShadow: '0 0 32px rgba(116,232,255,0.45)'
            }}
          />
          <div
            style={{
              position: 'absolute',
              left: cursorX * screenWidth - 44,
              top: cursorY * screenHeight - 44,
              width: 88,
              height: 88,
              borderRadius: 999,
              border: `2px solid ${accentPalette[safeIndex % accentPalette.length]}`,
              opacity: activeStep.gesture === 'tap' ? 0.62 : 0.34,
              transform: `scale(${1 + Math.sin(frame / 5) * 0.1})`
            }}
          />
          <div
            style={calloutPosition(activeStep, screenWidth, screenHeight)}
          >
            <div
              style={{
                borderRadius: 24,
                padding: '16px 18px',
                background: 'rgba(3,19,31,0.88)',
                border: '1px solid rgba(255,255,255,0.14)',
                boxShadow: '0 22px 48px rgba(0,0,0,0.28)',
                backdropFilter: 'blur(16px)'
              }}
            >
              <div
                style={{
                  fontFamily: brandTheme.fonts.mono,
                  fontSize: 14,
                  color: accentPalette[safeIndex % accentPalette.length]
                }}
              >
                ETAPE {safeIndex + 1}
              </div>
              <div
                style={{
                  marginTop: 6,
                  fontFamily: brandTheme.fonts.display,
                  fontSize: 24,
                  lineHeight: 1.1,
                  fontWeight: 700,
                  color: brandTheme.colors.paper
                }}
              >
                {activeStep.target}
              </div>
              <div
                style={{
                  marginTop: 10,
                  fontFamily: brandTheme.fonts.body,
                  fontSize: 16,
                  lineHeight: 1.45,
                  color: 'rgba(245,251,255,0.78)'
                }}
              >
                {steps[activeStep.step_index]}
              </div>
            </div>
          </div>
        </>
      ) : null}
    </div>
  );
};
