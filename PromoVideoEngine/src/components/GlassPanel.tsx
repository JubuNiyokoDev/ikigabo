import type {CSSProperties, PropsWithChildren} from 'react';
import {brandTheme} from '../lib/theme';

type GlassPanelProps = PropsWithChildren<{
  style?: CSSProperties;
}>;

export const GlassPanel: React.FC<GlassPanelProps> = ({children, style}) => {
  return (
    <div
      style={{
        borderRadius: 30,
        padding: '28px 30px',
        border: `1px solid ${brandTheme.colors.stroke}`,
        background:
          'linear-gradient(180deg, rgba(255,255,255,0.16) 0%, rgba(255,255,255,0.05) 100%)',
        boxShadow: '0 24px 80px rgba(0, 0, 0, 0.28)',
        backdropFilter: 'blur(28px)',
        ...style
      }}
    >
      {children}
    </div>
  );
};
