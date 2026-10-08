import React from 'react';
import {AbsoluteFill, interpolate, useCurrentFrame} from 'remotion';

/* TITLE — course-branded title card with subtle fade/zoom. */
export const TitleScene: React.FC<{title?: string; lesson_label?: string; lessonLabel?: string}> = (props) => {
  const frame = useCurrentFrame();
  const opacity = interpolate(frame, [0, 15], [0, 1], {extrapolateRight: 'clamp'});
  const scale = interpolate(frame, [0, 30], [0.96, 1], {extrapolateRight: 'clamp'});
  return (
    <AbsoluteFill style={{backgroundColor: '#0B1120', justifyContent: 'center', alignItems: 'center'}}>
      <div style={{opacity, transform: `scale(${scale})`, textAlign: 'center'}}>
        <div style={{color: '#50E6FF', fontFamily: 'Inter', fontSize: 34, letterSpacing: 4}}>
          {(props.lessonLabel ?? props.lesson_label ?? '').toUpperCase()}
        </div>
        <div style={{color: '#E8EEFA', fontFamily: 'Inter', fontSize: 84, fontWeight: 700, marginTop: 24}}>
          {props.title ?? ''}
        </div>
        <div style={{width: 120, height: 6, background: '#0078D4', margin: '36px auto 0', borderRadius: 3}} />
      </div>
    </AbsoluteFill>
  );
};
