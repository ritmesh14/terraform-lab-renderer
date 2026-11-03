import React from 'react';
import {AbsoluteFill, Img, Video, getStaticFiles, staticFile} from 'remotion';

// Optional Manim animation layer (VIDEO-MAKING-PROCESS.md section 6): plays
// the narration-synced Manim clip rendered by tools/generate_manim.py from
// the validated spec. If the clip is absent — Manim unavailable or the
// render failed — the scene's MANDATORY static fallback (a build_diagram.py
// SVG, rendered by generate_assets.py) is shown instead. The swap is
// recorded in <asset>.fallback.json and surfaces in quality-check.json, so
// it is never silent.
//
// NOTE: asset / fallback_asset arrive ALREADY prefixed with episodeDir by
// Episode.tsx (the single place that joins scene-relative paths) and keep
// their snake_case names from scenes.json — do not re-join here or the URL
// double-prefixes and 404s.
//
// TITLE-BAND LAYOUT (2026-11-03 fix): the label used to be absolutely
// positioned over full-frame media, so tall diagrams rose into it. The
// heading is now IN FLOW — the media contain-fits into the REMAINING area
// (flex: 1, minHeight: 0), the same reservation pattern as DiagramScene's
// caption. No label => the media area is the full frame, byte-identical to
// the previous layout.
export const ManimScene: React.FC<any> = ({
  asset,
  fallback_asset,
  label,
}) => {
  const hasVideo = asset ? getStaticFiles().some((f) => f.name === asset) : false;
  return (
    <AbsoluteFill style={{backgroundColor: '#0B1120'}}>
      {label ? (
        <div
          style={{
            flex: '0 0 auto',
            paddingTop: 36,
            paddingBottom: 20,
            paddingLeft: 96,
            paddingRight: 96,
            textAlign: 'center',
            color: '#E8EDF6',
            fontFamily: 'Inter, sans-serif',
            fontSize: 40,
            fontWeight: 600,
          }}
        >
          {label}
        </div>
      ) : null}
      <div
        style={{
          flex: '1 1 auto',
          minHeight: 0,
          display: 'flex',
          justifyContent: 'center',
          alignItems: 'center',
        }}
      >
        {hasVideo ? (
          <Video
            src={staticFile(asset)}
            style={{width: '100%', height: '100%', objectFit: 'contain'}}
          />
        ) : fallback_asset ? (
          <Img
            src={staticFile(fallback_asset)}
            style={{
              width: '100%',
              height: '100%',
              objectFit: 'contain',
              padding: 48,
              boxSizing: 'border-box',
            }}
          />
        ) : null}
      </div>
    </AbsoluteFill>
  );
};