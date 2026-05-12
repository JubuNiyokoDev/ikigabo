import type {CSSProperties} from 'react';
import {brandTheme} from '../lib/theme';

type SectionHeadingProps = {
  eyebrow: string;
  title: string;
  body: string;
  align?: CSSProperties['textAlign'];
  maxWidth?: number;
};

export const SectionHeading: React.FC<SectionHeadingProps> = ({
  eyebrow,
  title,
  body,
  align = 'left',
  maxWidth = 620
}) => {
  return (
    <div
      style={{
        display: 'flex',
        flexDirection: 'column',
        gap: 18,
        textAlign: align,
        maxWidth
      }}
    >
      <div
        style={{
          alignSelf: align === 'center' ? 'center' : 'flex-start',
          padding: '12px 18px',
          borderRadius: 999,
          border: '1px solid rgba(255,255,255,0.14)',
          background: 'rgba(255,255,255,0.08)',
          letterSpacing: '0.26em',
          textTransform: 'uppercase',
          fontFamily: brandTheme.fonts.body,
          fontSize: 20,
          fontWeight: 700,
          color: 'rgba(245, 251, 255, 0.78)'
        }}
      >
        {eyebrow}
      </div>
      <div
        style={{
          fontFamily: brandTheme.fonts.display,
          fontSize: 78,
          lineHeight: 1,
          fontWeight: 700,
          letterSpacing: '-0.05em',
          color: brandTheme.colors.paper
        }}
      >
        {title}
      </div>
      <div
        style={{
          fontFamily: brandTheme.fonts.body,
          fontSize: 28,
          lineHeight: 1.45,
          color: 'rgba(245, 251, 255, 0.8)'
        }}
      >
        {body}
      </div>
    </div>
  );
};
