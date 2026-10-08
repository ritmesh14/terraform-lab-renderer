import React from 'react';
import {AbsoluteFill, Img, staticFile} from 'remotion';

/* PORTAL — Playwright-captured controlled mock (assets/portal/). Live portal
 * screenshots appear only in designated real-world demo episodes. */
export const PortalScene: React.FC<{asset?: string; callout?: string}> = (props) => (
  <AbsoluteFill style={{backgroundColor: '#0B1120', justifyContent: 'center', alignItems: 'center'}}>
    {props.asset ? <Img src={staticFile(props.asset)} style={{maxWidth: '92%'}} /> : null}
    {props.callout ? (
      <div style={{position: 'absolute', bottom: 80, color: '#E8EEFA', fontFamily: 'Inter', fontSize: 36,
                   background: 'rgba(0,120,212,0.25)', padding: '12px 32px', borderRadius: 10}}>
        {props.callout}
      </div>
    ) : null}
  </AbsoluteFill>
);
