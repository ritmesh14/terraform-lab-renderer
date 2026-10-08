import React, {useEffect, useLayoutEffect, useMemo, useRef, useState} from 'react';
import {AbsoluteFill, Img, continueRender, delayRender, interpolate, staticFile, useCurrentFrame} from 'remotion';

/*
 * CODE — EXACT ACTIVE_LAB source, never rewritten (course-wide rule).
 *
 * Two display modes:
 *  1. STATIC (no steps): the pre-generated Shiki PNG from assets/code/, as
 *     before. highlight_lines are baked in by the asset pipeline.
 *  2. NARRATION-SYNCED (steps present): fetches the Shiki HTML file that
 *     render_code_html.mjs writes beside the PNG (`<span class="line">` per
 *     source line) and focuses the line(s) the narration is talking about:
 *     active lines 1.0, adjacent lines 0.7, unrelated lines 0.5 — driven by
 *     the step's active_lines (absolute source line numbers) and the
 *     step_frames windows measured from the actual narration audio (TTS is
 *     the timing authority). Without step_frames the FIRST step stays lit.
 * 3. TOKEN-LEVEL FOCUS (step.active_tokens present): tokens named by the
 *     active step are wrapped in spans over the Shiki HTML (built once when
 *     the HTML lands; indexOf matching, longest-token-first so inner tokens
 *     nest inside outer ones — different steps may light overlapping text) and lit only while their step is active, so the
 *     highlight follows the narration. No active_tokens => line-level
 *     behavior only (identical to pre-2026-09-26 renders). Word-timing
 *     sub-step granularity is a future enhancement; step granularity already
 *     matches one narration sentence per step.
 * The PNG remains the fallback and the visual ground truth; the HTML is only
 * ever shown with identical Shiki output.
 */

export type CodeStep = {
  narration?: string;
  active_lines?: number[];
  active_tokens?: string[]; // tokens to light during this step (exact substrings)
};

export type StepFrames = {key: string; start: number; end: number}[];

const DIM = 0.5;
const NEAR = 0.7;
const RAMP = 8;

export const CodeScene: React.FC<{
  asset?: string;
  source_file?: string;
  highlight_lines?: number[];
  start_line?: number;
  steps?: CodeStep[];
  step_frames?: StepFrames;
}> = (props) => {
  const frame = useCurrentFrame();
  const {steps, step_frames: sf, start_line: base} = props;
  const synced = !!steps && steps.length > 0 && !!sf && sf.length === steps.length;
  const enter = interpolate(frame, [0, 10], [0, 1], {extrapolateRight: 'clamp'});

  // static PNG mode
  if (!synced) {
    return (
      <AbsoluteFill style={{backgroundColor: '#0B1120', padding: 96}}>
        {props.source_file ? (
          <div style={{color: '#50E6FF', fontFamily: 'JetBrains Mono', fontSize: 30, marginBottom: 24, opacity: enter}}>
            {props.source_file}
          </div>
        ) : null}
        {props.asset ? (
          <Img src={staticFile(props.asset)} style={{maxWidth: '100%', maxHeight: '86%', objectFit: 'contain', opacity: enter}} />
        ) : null}
      </AbsoluteFill>
    );
  }

  // narration-synced HTML mode
  return <SyncedCode {...props} synced={synced} enter={enter} />;
};

const SyncedCode: React.FC<{
  asset?: string;
  source_file?: string;
  steps?: CodeStep[];
  step_frames?: StepFrames;
  start_line?: number;
  synced: boolean;
  enter: number;
}> = (props) => {
  const frame = useCurrentFrame();
  const hostRef = useRef<HTMLDivElement>(null);
  const [htmlText, setHtmlText] = useState<string | null>(null);
  const [handle] = useState(() => delayRender('code html load'));

  useEffect(() => {
    if (!props.asset) {
      continueRender(handle);
      return;
    }
    let cancelled = false;
    // the Shiki HTML lives beside the PNG; same stem, .html extension
    const htmlAsset = props.asset.replace(/\.(png|svg)$/i, '.html');
    fetch(staticFile(htmlAsset))
      .then((r) => {
        if (!r.ok) {
          throw new Error(`missing ${htmlAsset}`);
        }
        return r.text();
      })
      .then((text) => {
        if (!cancelled) {
          setHtmlText(text);
        }
        continueRender(handle);
      })
      .catch(() => {
        // no HTML beside the PNG — never break the render; static mode is the
        // visual ground truth
        if (!cancelled) {
          setHtmlText('');
        }
        continueRender(handle);
      });
    return () => {
      cancelled = true;
    };
  }, [props.asset, handle]);

  // which step is lit at this frame (first step before its window)
  const activeIdx = useMemo(() => {
    const sf = props.step_frames!;
    let idx = 0;
    for (let i = 0; i < sf.length; i++) {
      if (frame >= sf[i].start) {
        idx = i;
      }
    }
    return idx;
  }, [frame, props.step_frames]);
  const activeLines = new Set(props.steps![activeIdx].active_lines ?? []);

  // per-line opacity timeline, memoized once per active-step change
  const lineOpacity = useMemo(() => {
    const baseLine = props.start_line ?? 1;
    return (i: number) => {
      const lineNo = baseLine + i;
      if (activeLines.has(lineNo)) {
        return 1.0;
      }
      // adjacent lines stay near-full so context is readable
      for (const l of activeLines) {
        if (Math.abs(l - lineNo) <= 1) {
          return NEAR;
        }
      }
      return DIM;
    };
  }, [activeLines, props.start_line]);

  // ---- token-level focus (active_tokens) ----
  // Wrapped spans over the Shiki HTML, built ONCE when the HTML lands.
  // props identity changes per frame in Remotion, so steps are read via a ref.
  type TokenWrap = {el: HTMLElement; token: string; lineIndex: number};
  const tokenWrappers = useRef<TokenWrap[]>([]);
  const stepsRef = useRef(props.steps);
  stepsRef.current = props.steps;

  useLayoutEffect(() => {
    tokenWrappers.current = [];
    const host = hostRef.current;
    if (!host || !htmlText) {
      return;
    }
    const allTokens = new Set<string>();
    (stepsRef.current ?? []).forEach((s) =>
      (s.active_tokens ?? []).forEach((t) => {
        if (t) {
          allTokens.add(t);
        }
      }));
    if (allTokens.size === 0) {
      return;
    }
    // longest first so an outer token (data-${count.index}) wraps before an
    // inner one (count.index) — the inner token then nests inside it
    const sorted = [...allTokens].sort((a, b) => b.length - a.length);
    const missing = new Set(allTokens);
    const wrappers: TokenWrap[] = [];

    host.querySelectorAll<HTMLElement>('.line').forEach((ln, lineIndex) => {
      // per-token pass, longest first: an outer token (data-${count.index})
      // wraps before an inner one (count.index), so the inner token is found
      // INSIDE the outer wrapper and gets a nested span — different steps may
      // light overlapping text, so tokens never steal each other's ranges
      for (const tok of sorted) {
        // fresh snapshot per token (earlier wraps changed the DOM)
        const nodes: Text[] = [];
        const starts: number[] = [];
        let text = '';
        const walker = document.createTreeWalker(ln, NodeFilter.SHOW_TEXT);
        let n: Node | null = walker.nextNode();
        while (n) {
          const t = n as Text;
          nodes.push(t);
          starts.push(text.length);
          text += t.data;
          n = walker.nextNode();
        }
        if (!text) {
          return;
        }
        const hits: {s: number; e: number}[] = [];
        let from = 0;
        for (;;) {
          const at = text.indexOf(tok, from);
          if (at < 0) {
            break;
          }
          from = at + 1;
          hits.push({s: at, e: at + tok.length});
          missing.delete(tok);
        }
        // wrap right-to-left so earlier offsets stay valid
        hits.sort((a, b) => b.s - a.s);
        for (const h of hits) {
          for (let i = nodes.length - 1; i >= 0; i--) {
            const nodeStart = starts[i];
            const nodeEnd = nodeStart + nodes[i].data.length;
            if (nodeEnd <= h.s || nodeStart >= h.e) {
              continue;
            }
            const sOff = Math.max(h.s, nodeStart) - nodeStart;
            const eOff = Math.min(h.e, nodeEnd) - nodeStart;
            let target: Text = nodes[i];
            if (eOff < target.data.length) {
              target.splitText(eOff); // right remainder becomes a sibling
            }
            if (sOff > 0) {
              target = target.splitText(sOff); // target is now the middle node
            }
            const span = document.createElement('span');
            span.className = 'token-hl';
            target.parentNode!.insertBefore(span, target);
            span.appendChild(target);
            wrappers.push({el: span, token: tok, lineIndex});
          }
        }
      }
    });
    tokenWrappers.current = wrappers;
    if (missing.size > 0) {
      // never fail the render — a token that is not in the source just never
      // lights; the validator (validate_scene_schema.py) catches this earlier
      console.warn('[CodeScene] active_tokens not found in source:',
        [...missing]);
    }
  }, [htmlText]);

  // per-frame token toggle: class only, no DOM mutation (Remotion-safe)
  useLayoutEffect(() => {
    if (tokenWrappers.current.length === 0) {
      return;
    }
    const activeTokens = new Set(stepsRef.current?.[activeIdx]?.active_tokens ?? []);
    const baseLine = props.start_line ?? 1;
    for (const w of tokenWrappers.current) {
      const on = activeLines.has(baseLine + w.lineIndex) && activeTokens.has(w.token);
      w.el.classList.toggle('token-hl-on', on);
    }
  }, [frame, activeIdx, activeLines, props.start_line]);

  // apply styles synchronously before paint
  useLayoutEffect(() => {
    const host = hostRef.current;
    if (!host || htmlText === null) {
      return;
    }
    host.querySelectorAll<HTMLElement>('.line').forEach((ln, i) => {
      const o = lineOpacity(i);
      ln.style.opacity = String(o);
    });
  }, [frame, htmlText, lineOpacity, activeIdx]);

  const firstActive = [...activeLines].sort((a, b) => a - b);

  // LAYOUT_QC (§33.3, test-render feedback 2026-09-26): the injected Shiki
  // HTML carries its OWN stylesheet — `.wrap { padding: 56px 72px }` and
  // `pre, code { font-size: 34px !important; line-height: 1.5 !important }`.
  // Those !important rules beat the host's inline fontSize, so a fixed 34px
  // clipped longer blocks off the host's top and bottom (overflow hidden +
  // centered). Size the code from the actual line count so the WHOLE teaching
  // unit always fits, and neutralize the injected rules with a later
  // same-specificity !important override (rendered after the host div below).
  // count BOTH `class="line"` and `class="line hl"` (highlight-baked lines
  // carry the extra class — a plain split on 'class="line"' missed them and
  // oversized the font until it overflowed again)
  const lineCount = Math.max(1, (htmlText ?? '').match(/class="line[" ]/g)?.length ?? 1);
  const hostH = 0.86 * (1080 - 2 * 96);
  const codeFont = Math.max(20, Math.min(36, Math.floor(hostH / 1.42 / lineCount)));

  return (
    <AbsoluteFill style={{backgroundColor: '#0B1120', padding: 96}}>
      <style>{`
        .token-hl { border-radius: 3px; }
        .token-hl-on {
          background: rgba(80, 230, 255, 0.26);
          border-radius: 3px;
          box-shadow: 0 0 12px rgba(80, 230, 255, 0.45);
        }
      `}</style>
      {props.source_file ? (
        <div style={{color: '#50E6FF', fontFamily: 'JetBrains Mono', fontSize: 30, marginBottom: 24, opacity: props.enter}}>
          {props.source_file}
        </div>
      ) : null}
      <div
        ref={hostRef}
        style={{
          width: '100%',
          height: '86%',
          overflow: 'hidden',
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'center',
          fontFamily: 'JetBrains Mono',
          fontSize: codeFont,
          lineHeight: 1.42,
          opacity: props.enter,
        }}
        dangerouslySetInnerHTML={{__html: htmlText ?? ''}}
      />
      {htmlText !== null ? (
        // must come AFTER the host div: same specificity + !important, later
        // in document order — beats the injected stylesheet's 34px/1.5 and the
        // .wrap padding (FONT/LAYOUT_QC, 2026-09-26)
        <style>{`
          pre, code { font-size: ${codeFont}px !important; line-height: 1.42 !important; }
          .wrap { padding: 0 !important; }
        `}</style>
      ) : null}
      {firstActive.length > 0 ? (
        <div
          style={{
            color: '#9BD1FF',
            fontFamily: 'JetBrains Mono',
            fontSize: 28,
            marginTop: 16,
            opacity: props.enter,
          }}
        >
          {`line${firstActive.length > 1 ? 's' : ''} ${firstActive.join(', ')} of ${props.source_file ?? 'main.tf'}`}
        </div>
      ) : null}
    </AbsoluteFill>
  );
};