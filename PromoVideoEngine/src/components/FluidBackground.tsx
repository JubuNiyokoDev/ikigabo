import type {CSSProperties} from 'react';
import {AbsoluteFill} from 'remotion';
import {brandTheme} from '../lib/theme';

type Orb = {
  size: number;
  left: number;
  top: number;
  speedX: number;
  speedY: number;
  amplitudeX: number;
  amplitudeY: number;
  color: string;
  phase: number;
  opacity?: number;
};

type FluidBackgroundProps = {
  frame: number;
  palette?: [string, string, string];
};

const orbStyle = (orb: Orb, frame: number): CSSProperties => {
  const x = orb.left + Math.sin(frame / orb.speedX + orb.phase) * orb.amplitudeX;
  const y = orb.top + Math.cos(frame / orb.speedY + orb.phase) * orb.amplitudeY;
  const scale = 1 + Math.sin(frame / 80 + orb.phase) * 0.08;

  return {
    position: 'absolute',
    width: orb.size,
    height: orb.size,
    left: x,
    top: y,
    borderRadius: '50%',
    filter: 'blur(120px)',
    opacity: orb.opacity ?? 0.75,
    transform: `scale(${scale})`,
    mixBlendMode: 'screen',
    background: `radial-gradient(circle at 35% 35%, ${orb.color}, transparent 72%)`
  };
};

export const FluidBackground: React.FC<FluidBackgroundProps> = ({frame, palette}) => {
  const [accentA, accentB, accentC] = palette ?? [
    brandTheme.colors.accent,
    brandTheme.colors.mint,
    brandTheme.colors.coral
  ];

  const orbs: Orb[] = [
    {
      size: 520,
      left: 90,
      top: 80,
      speedX: 48,
      speedY: 60,
      amplitudeX: 36,
      amplitudeY: 28,
      color: accentA,
      phase: 0.3
    },
    {
      size: 720,
      left: 1180,
      top: -60,
      speedX: 72,
      speedY: 52,
      amplitudeX: 58,
      amplitudeY: 34,
      color: accentB,
      phase: 1.5,
      opacity: 0.62
    },
    {
      size: 660,
      left: 1180,
      top: 560,
      speedX: 54,
      speedY: 76,
      amplitudeX: 42,
      amplitudeY: 46,
      color: accentC,
      phase: 2.1,
      opacity: 0.58
    },
    {
      size: 440,
      left: 420,
      top: 660,
      speedX: 66,
      speedY: 44,
      amplitudeX: 30,
      amplitudeY: 24,
      color: accentA,
      phase: 3.1,
      opacity: 0.38
    }
  ];

  return (
    <AbsoluteFill
      style={{
        overflow: 'hidden',
        background:
          'linear-gradient(135deg, #03131F 0%, #082335 42%, #041925 100%)'
      }}
    >
      {orbs.map((orb, index) => (
        <div key={index} style={orbStyle(orb, frame)} />
      ))}
      <AbsoluteFill
        style={{
          background:
            'radial-gradient(circle at top left, rgba(255,255,255,0.12), transparent 28%), radial-gradient(circle at bottom right, rgba(255,255,255,0.08), transparent 30%)'
        }}
      />
      <AbsoluteFill
        style={{
          opacity: 0.12,
          backgroundImage:
            'linear-gradient(rgba(255,255,255,0.12) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,0.08) 1px, transparent 1px)',
          backgroundSize: '140px 140px'
        }}
      />
      <AbsoluteFill
        style={{
          background:
            'linear-gradient(180deg, rgba(255,255,255,0.08) 0%, transparent 18%, transparent 82%, rgba(0,0,0,0.32) 100%)'
        }}
      />
    </AbsoluteFill>
  );
};
