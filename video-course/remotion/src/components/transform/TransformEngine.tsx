import React, {useLayoutEffect, useMemo, useRef, useState} from 'react';
import {AbsoluteFill, continueRender, delayRender, interpolate, useCurrentFrame} from 'remotion';

/*
 * TRANSFORM ENGINE — generic schema-driven scene for section-02's
 * transformation stories (count expansion, for_each mapping, splat
 * addressing, dynamic blocks, ...). The scenes.json entry carries the data:
 *
 *   title:      scene heading
 *   expression: the source expression the stage flow derives from (mono, cyan)
 *   stages:     [{id, label, kind?, items: [{key, text, mono?}]}] — lanes left
 *               to right in story order (expression -> instances ->
 *               addresses -> output -> note)
 *   steps:      [{narration, focus?: {stages?: string[], items?: string[]}}]
 *   step_frames:[{key, start, end}]  (timed-scenes.json; TTS is the timing
 *               authority — frames RELATIVE to scene start)
 *
 * Activation copies DiagramScene's breakpoints pattern: the step whose window
 * contains the frame is active; focused items render full + cyan glow,
 * everything else dims to 0.5. Items never named in any step show as overview
 * until the first step, then dim. Thin per-type wrappers
 * (IterationExpansionScene, StateAddressScene, ...) exist so episodes get
 * stable named components and per-type extras have a home; the rendering
 * lives here so eight transform stories do not duplicate it.
 */

export type TransformItem = {key: string; text: string; mono?: boolean};

export type TransformStage = {
  id: string;
  label: string;
  kind?: 'expression' | 'instances' | 'addresses' | 'output' | 'note';
  items: TransformItem[];
};

export type TransformStep = {
  narration?: string;
  focus?: {stages?: string[]; items?: string[]};
};

export type StepFrames = {key: string; start: number; end: number}[];

const DIM = 0.5;
const RAMP = 8;

const KIND_COLORS: Record<string, string> = {
  expression: '#50E6FF',
  instances: '#9BD1FF',
  addresses: '#C9D3E8',
  output: '#7EE2B8',
  note: '#E8B15C',
};

export const TransformEngine: React.FC<{
  title?: string;
  expression?: string;
  stages?: TransformStage[];
  steps?: TransformStep[];
  step_frames?: StepFrames;
}> = (props) => {
  const frame = useCurrentFrame();
  const {stages = [], steps = [], step_frames: sf} = props;

  const synced = steps.length > 0 && !!sf && sf.length === steps.length;
  const activeIdx = useMemo(() => {
    if (!synced) {
      return -1;
    }
    let idx = 0;
    for (let i = 0; i < sf.length; i++) {
      if (frame >= sf[i].start) {
        idx = i;
      }
    }
    return idx;
  }, [frame, sf, synced]);

  const enter = interpolate(frame, [0, 20], [0, 1], {extrapolateRight: 'clamp'});

  const itemState = (stageId: string, itemKey: string, firstStepStart: number): number => {
    if (!synced || activeIdx < 0) {
      return 1; // overview before/without steps
    }
    // breakpoints per item, DiagramScene-style
    const pts: [number, number][] = [[0, 1]];
    for (let i = 0; i < steps.length; i++) {
      const focus = steps[i].focus ?? {};
      const hit = (focus.items ?? []).includes(itemKey)
        || (focus.stages ?? []).includes(stageId);
      const target = hit ? 1 : DIM;
      const start = Math.max(sf[i].start, firstStepStart);
      const prev = pts[pts.length - 1][1];
      if (target !== prev) {
        if (pts[pts.length - 1][0] !== start) {
          pts.push([start, prev]);
        }
        pts.push([start + RAMP, target]);
      }
    }
    pts.push([sf[sf.length - 1].end + 120, pts[pts.length - 1][1]]);
    return interpolate(frame,
      pts.map((p) => p[0]), pts.map((p) => p[1]),
      {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  };

  const glowOf = (v: number) => Math.max(0, v - DIM) / (1 - DIM);

  // CODE_WRAP_QC (§33.4): mono tokens (addresses, expressions) must never
  // wrap mid-token. Size the card font from the content: sum every lane's
  // longest mono token and shrink the font until all lanes fit the 1728px
  // content width (JetBrains Mono advance ≈ 0.6em). Clamped 20–30px.
  const CONTENT_W = 1920 - 2 * 96;
  const lanes = stages.map((st) => Math.max(
    10, ...(st.items ?? []).filter((it) => it.mono !== false).map((it) => it.text.length)));
  const totalChars = lanes.reduce((a, b) => a + b, 0);
  const avail = CONTENT_W - (stages.length - 1) * 80 - stages.length * 40;
  const cardFont = Math.max(20, Math.min(30, Math.floor(avail / (0.6 * Math.max(1, totalChars)))));

  // MEASURED-ANCHOR ARROWS (ARROW_ENDPOINT_QC, user feedback 2026-09-26 —
  // "this arrow problem is occurring all the time"). Every previous attempt
  // INFERRED arrow positions from layout rules (flex centering, averaged Y,
  // label-band offsets) and broke whenever lane heights differed. The
  // industry pattern (react-xarrows, LeaderLine, React Flow — researched
  // 2026-09-26) is to MEASURE the real DOM elements with
  // getBoundingClientRect and draw connectors in an SVG overlay between the
  // measured points: the geometry can never drift from the cards because it
  // IS the cards' geometry. Scene data is static per episode, so one measure
  // after mount is enough (fonts are guaranteed loaded before render by
  // fonts.ts's ensureFonts gate).
  const rowRef = useRef<HTMLDivElement>(null);
  const cardsRefs = useRef<(HTMLDivElement | null)[]>([]);
  const [conns, setConns] = useState<{x1: number; y1: number; x2: number; y2: number}[]>([]);
  const stageSig = stages.map((s) => `${s.id}:${(s.items ?? []).length}`).join('|');
  const measure = () => {
    const row = rowRef.current;
    if (!row) {
      return;
    }
    const rowRect = row.getBoundingClientRect();
    const next: {x1: number; y1: number; x2: number; y2: number}[] = [];
    for (let i = 0; i < stages.length - 1; i++) {
      const a = cardsRefs.current[i];
      const b = cardsRefs.current[i + 1];
      if (!a || !b) {
        continue;
      }
      const ra = a.getBoundingClientRect();
      const rb = b.getBoundingClientRect();
      next.push({
        x1: ra.right - rowRect.left,
        y1: ra.top + ra.height / 2 - rowRect.top,
        x2: rb.left - rowRect.left,
        y2: rb.top + rb.height / 2 - rowRect.top,
      });
    }
    setConns((prev) =>
      prev.length === next.length &&
      prev.every((p, i) =>
        p.x1 === next[i].x1 && p.y1 === next[i].y1 &&
        p.x2 === next[i].x2 && p.y2 === next[i].y2)
        ? prev : next);
  };
  useLayoutEffect(() => {
    measure();
    // CRITICAL: the first synchronous measure can run while fallback fonts
    // are still laid out (font swap re-flows the cards afterward) — the
    // measured geometry then no longer matches the visible cards (exactly
    // the class of drift this refactor exists to kill). Re-measure once the
    // real fonts are committed, and hold the frame (delayRender) until then
    // so Remotion never screenshots the stale geometry.
    const handle = delayRender('transform arrow font measure');
    let cancelled = false;
    document.fonts.ready.then(() => {
      if (!cancelled) {
        measure();
      }
      continueRender(handle);
    });
    return () => {
      cancelled = true;
      continueRender(handle);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [stageSig]);

  return (
    <AbsoluteFill style={{backgroundColor: '#0B1120', padding: 96}}>
      {props.title ? (
        <div style={{
          color: '#E8EEFA', fontFamily: 'Inter', fontSize: 48, fontWeight: 600,
          marginBottom: 12, opacity: enter,
        }}>{props.title}</div>
      ) : null}
      {props.expression ? (
        <div style={{
          color: '#50E6FF', fontFamily: 'JetBrains Mono', fontSize: 32,
          marginBottom: 36, opacity: enter,
        }}>{props.expression}</div>
      ) : null}
      <div ref={rowRef} style={{
        position: 'relative',
        display: 'flex', flexDirection: 'row', alignItems: 'flex-start',
        gap: 56, opacity: enter,
      }}>
        {stages.map((st, si) => (
          <div key={st.id} style={{
            // flex-basis auto: lanes size to their content first (long
            // unbreakable mono tokens keep their width — CODE_WRAP_QC),
            // then grow to fill; an equal 0 basis lets the address lane
            // crush the result lane into mid-token wraps.
            flex: '1 1 auto', minWidth: 0,
            display: 'flex', flexDirection: 'column', gap: 12,
          }}>
            <div style={{
              color: KIND_COLORS[st.kind ?? 'addresses'] ?? '#C9D3E8',
              fontFamily: 'Inter', fontSize: 26, fontWeight: 600,
              letterSpacing: 2, textTransform: 'uppercase', marginBottom: 4,
            }}>{st.label}</div>
            <div ref={(el) => { cardsRefs.current[si] = el; }}
                 style={{display: 'flex', flexDirection: 'column', gap: 12}}>
            {(st.items ?? []).map((it) => {
              const v = itemState(st.id, it.key, sf?.[0]?.start ?? 0);
              const glow = glowOf(v);
              return (
                <div key={it.key} style={{
                  fontFamily: it.mono === false ? 'Inter' : 'JetBrains Mono',
                  fontSize: cardFont, color: '#E8EEFA',
                  backgroundColor: '#111A2E',
                  border: '1px solid #1E2B45', borderRadius: 10,
                  padding: '14px 20px',
                  opacity: v,
                  boxShadow: glow > 0.02
                    ? `0 0 ${(12 * glow).toFixed(1)}px rgba(80,230,255,${(0.6 * glow).toFixed(2)})`
                    : 'none',
                  transform: `scale(${(1 + 0.02 * glow).toFixed(4)})`,
                }}>{it.text}</div>
              );
            })}
            </div>
          </div>
        ))}
        {conns.length > 0 ? (
          <svg style={{position: 'absolute', top: 0, left: 0, width: '100%',
                       height: '100%', pointerEvents: 'none'}}>
            <defs>
              <marker id="te-arrowhead" markerWidth="12" markerHeight="12"
                      refX="9" refY="5" orient="auto" markerUnits="userSpaceOnUse">
                <path d="M0,0 L10,5 L0,10 z" fill="#3B4C6B" />
              </marker>
            </defs>
            {conns.map((c, i) => (
              <line key={i} x1={c.x1} y1={c.y1} x2={c.x2 - 2} y2={c.y2}
                    stroke="#3B4C6B" strokeWidth={3} markerEnd="url(#te-arrowhead)" />
            ))}
          </svg>
        ) : null}
      </div>
    </AbsoluteFill>
  );
};