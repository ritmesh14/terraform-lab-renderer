import React from 'react';
import {AbsoluteFill, useCurrentFrame, interpolate} from 'remotion';

/*
 * NEXT — fixed real-world-demo transition. Narration is ALWAYS:
 * "Now that we understand how this Terraform configuration works, in the next
 *  part of this video, we'll move to a real-world demo and deploy it in
 *  Microsoft Azure."
 */
export const NextEpisodeScene: React.FC = () => {
  const frame = useCurrentFrame();
  const o = interpolate(frame, [0, 15], [0, 1], {extrapolateRight: 'clamp'});
  return (
    <AbsoluteFill style={{backgroundColor: '#0B1120', justifyContent: 'center', alignItems: 'center', opacity: o}}>
      <div style={{color: '#50E6FF', fontFamily: 'Inter', fontSize: 36, letterSpacing: 6}}>NEXT</div>
      <div style={{color: '#E8EEFA', fontFamily: 'Inter', fontSize: 72, fontWeight: 700, marginTop: 20}}>
        Real-World Demo
      </div>
      <div style={{color: '#C9D3E8', fontFamily: 'Inter', fontSize: 40, marginTop: 26}}>
        Terraform → Microsoft Azure
      </div>
    </AbsoluteFill>
  );
};
