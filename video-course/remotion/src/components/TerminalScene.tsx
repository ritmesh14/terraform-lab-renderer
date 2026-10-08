import React from 'react';
import {AbsoluteFill, Img, staticFile} from 'remotion';

/* TERMINAL — deterministic render_terminal_svg.py output (assets/terminal/).
 * LAYOUT_QC (§33.3): contain-fit BOTH dimensions so a long plan/apply SVG
 * (some are >1080px tall) scales down instead of clipping off the bottom
 * edge — the lowest ~8% stays clear for player controls. */
export const TerminalScene: React.FC<{asset?: string}> = (props) => (
  <AbsoluteFill style={{backgroundColor: '#0B1120', justifyContent: 'center', alignItems: 'center'}}>
    {props.asset ? (
      <Img
        src={staticFile(props.asset)}
        style={{maxWidth: '88%', maxHeight: '90%', objectFit: 'contain'}}
      />
    ) : null}
  </AbsoluteFill>
);
