import React from 'react';
import {Composition} from 'remotion';
import {Episode, EpisodeProps} from './Episode';
import {ensureFonts} from './fonts';

// FONT_QC: register + verify the course fonts before any frame renders
// (§33.1 — a silent serif fallback must fail the render, not ship).
ensureFonts();

/*
 * One parameterized composition. generate_course.py renders it with
 * --props pointing at the episode folder; Episode.tsx reads
 * timing/timed-scenes.json + writing/scenes.json from those props.
 *
 * The authoritative timeline is timed-scenes.json (frames derived from
 * MEASURED MiniMax audio, config/theme.json fps, config/voice.json padding).
 */
const defaultProps: EpisodeProps = {
  episodeDir: '',
  publicLabUrl: '',
  title: 'Terraform on Azure',
  lessonLabel: '',
};

export const RemotionRoot: React.FC = () => (
  <>
    <Composition
      id="Episode"
      component={Episode}
      durationInFrames={30 * 10}
      fps={30}
      width={1920}
      height={1080}
      defaultProps={defaultProps}
      calculateMetadata={({props}) => {
        // Duration comes from the episode's measured timeline when present.
        const total = (props as EpisodeProps).totalDurationFrames;
        return total ? {durationInFrames: total} : {};
      }}
    />
  </>
);
