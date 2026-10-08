import React, {useMemo} from 'react';
import {AbsoluteFill, interpolate, useCurrentFrame} from 'remotion';

/*
 * CONCEPT — text/teaching scene; also renders the "where this lab lives"
 * GitHub breadcrumb (NEVER local paths) when github_path is provided.
 * centered: true vertically/horizontally centers the content (outro scene).
 *
 * Progressive reveal (instruction §18): when the scene has narration steps +
 * measured step_frames, each point fades in as the narration reaches it —
 * matched by keyword overlap between the point text and the step narration
 * (deterministic; no LLM at render time). Without steps the whole set fades in
 * proportionally, as before. A point never appears before its step's narration
 * mentions it; all points are lit by the scene end.
 */

export type StepFrames = {key: string; start: number; end: number}[];

const STOP = new Set(['the', 'a', 'an', 'and', 'or', 'of', 'to', 'in', 'is', 'are',
  'it', 'this', 'that', 'with', 'for', 'on', 'as', 'we', 'our', 'you', 'your']);

const keywords = (text: string): Set<string> =>
  new Set(text.toLowerCase().split(/[^a-z0-9_]+/).filter((w) => w.length > 2 && !STOP.has(w)));

// LAYOUT_QC (§33.3, test-render feedback 2026-09-26): a fixed 40px left
// 3-point scenes mostly empty. Size the point text from the content: the
// longest point must fit the 1680px text width (Inter ≈ 0.52em average
// advance), capped by how many points there are — fewer points, larger type.
export const pointFont = (points: string[]): number => {
  const longest = Math.max(20, ...points.map((p) => p.length));
  const fit = Math.floor(1680 / (0.52 * longest));
  const byCount = points.length <= 3 ? 60 : points.length <= 4 ? 52 : 46;
  return Math.max(36, Math.min(byCount, fit));
};

export const ConceptScene: React.FC<{
  heading?: string;
  points?: string[];
  numbered?: boolean;
  github_path?: string;
  publicLabUrl?: string;
  centered?: boolean;
  steps?: {narration?: string; [k: string]: unknown}[];
  step_frames?: StepFrames;
}> = (props) => {
  const frame = useCurrentFrame();
  const {points, steps, step_frames: sf} = props;
  const synced = !!points && !!steps && steps.length > 0 && !!sf && sf.length === steps.length;

  // step start frames (used as fallback reveal times)
  const stepStarts = useMemo<number[] | null>(() => {
    if (!synced || !points) {
      return null;
    }
    return steps!.map((_, i) => sf![i].start);
  }, [synced, points, steps, sf]);

  // deterministic keyword match: point reveals in the first step that names it
  const matchedStart = useMemo<number[] | null>(() => {
    if (!stepStarts || !points || !steps) {
      return null;
    }
    const kw = points.map(keywords);
    const starts: number[] = [];
    for (let p = 0; p < points.length; p++) {
      let start = -1;
      for (let i = 0; i < steps.length && start < 0; i++) {
        const skw = keywords(steps[i].narration ?? '');
        for (const w of kw[p]) {
          if (skw.has(w)) {
            start = stepStarts[i];
            break;
          }
        }
      }
      // fallback for never-mentioned points: proportional between step starts
      starts.push(start >= 0 ? start : stepStarts[Math.min(p, stepStarts.length - 1)]);
    }
    return starts;
  }, [stepStarts, points, steps, sf]);

  const starts = synced && matchedStart ? matchedStart : null;

  const pf = props.points ? pointFont(props.points) : 40;

  const opacityFor = (i: number) => {
    const s = starts ? starts[i] : 12 + i * 12;
    return interpolate(frame, [s, s + 10], [0, 1], {extrapolateRight: 'clamp'});
  };

  return (
    <AbsoluteFill style={{backgroundColor: '#0B1120', padding: 120, fontFamily: 'Inter',
                         display: 'flex', flexDirection: 'column',
                         alignItems: props.centered ? 'center' : 'flex-start',
                         justifyContent: props.centered ? 'center' : 'flex-start',
                         textAlign: props.centered ? 'center' : 'left'}}>
      {props.heading ? (
        <div style={{color: '#E8EEFA', fontSize: 60, fontWeight: 700}}>{props.heading}</div>
      ) : null}
      {props.github_path ? (
        <div style={{color: '#50E6FF', fontFamily: 'JetBrains Mono', fontSize: 30, marginTop: 36, lineHeight: 1.8, whiteSpace: 'pre'}}>
          {props.github_path}
        </div>
      ) : null}
      {/* LAYOUT_QC (§33.3): non-centered scenes place their content a fixed,
          modest distance below the heading (user feedback 2026-09-26: a
          centered block left a too-large heading→content gap) — top-anchored,
          not floating in the middle of the frame. */}
      <div style={{flex: 1, display: 'flex', flexDirection: 'column',
                   justifyContent: 'flex-start',
                   paddingTop: props.centered ? 0 : 48,
                   alignItems: props.centered ? 'center' : 'flex-start',
                   width: '100%'}}>
      {(props.points ?? []).map((p, i) => props.numbered ? (
        // numbered layout (user-set 2026-09-25): visible 1/2/3 chips so each
        // spoken point maps to exactly one on-screen line
        <div key={i} style={{display: 'flex', alignItems: 'center',
                             marginTop: i === 0 ? 0 : Math.round(pf * 0.55),
                             opacity: opacityFor(i)}}>
          <div style={{width: pf + 10, height: pf + 10, borderRadius: (pf + 10) / 2, flexShrink: 0,
                       border: '2px solid #50E6FF', color: '#50E6FF',
                       display: 'flex', alignItems: 'center', justifyContent: 'center',
                       fontSize: Math.round(pf * 0.55), fontWeight: 700, fontFamily: 'JetBrains Mono',
                       marginRight: Math.round(pf * 0.5)}}>{i + 1}</div>
          <div style={{color: '#C9D3E8', fontSize: pf}}>{p}</div>
        </div>
      ) : (
        <div key={i} style={{color: '#C9D3E8', fontSize: pf,
                             marginTop: i === 0 ? 0 : Math.round(pf * 0.55),
                             opacity: opacityFor(i)}}>
          {p}
        </div>
      ))}
      </div>
    </AbsoluteFill>
  );
};