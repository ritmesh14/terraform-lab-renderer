/*
 * FONT_QC (production plan §33.1, added 2026-09-26): the course typography is
 * Inter (UI / titles / labels) + JetBrains Mono (Terraform code / terminal /
 * addresses). Both families are bundled under public/fonts/ and registered
 * here with @font-face, so renders never depend on fonts installed on the
 * render machine (the lab-26 test render silently fell back to a serif face
 * because only theme.json NAMED the fonts — nothing loaded them).
 *
 * ensureFonts() runs before the first frame: it blocks the render
 * (delayRender) until every face has finished loading, then verifies each
 * family actually RESOLVED via document.fonts.check. A family that fails to
 * resolve throws — FONT_QC = FAIL, DO NOT RENDER — instead of silently
 * rendering Times New Roman / Georgia.
 */

import {continueRender, delayRender, staticFile} from 'remotion';

const FONTS: {family: string; file: string; weight: number}[] = [
  {family: 'Inter', file: 'inter-latin-400-normal.woff2', weight: 400},
  {family: 'Inter', file: 'inter-latin-500-normal.woff2', weight: 500},
  {family: 'Inter', file: 'inter-latin-600-normal.woff2', weight: 600},
  {family: 'Inter', file: 'inter-latin-700-normal.woff2', weight: 700},
  {family: 'JetBrains Mono', file: 'jetbrains-mono-latin-400-normal.woff2', weight: 400},
  {family: 'JetBrains Mono', file: 'jetbrains-mono-latin-700-normal.woff2', weight: 700},
];

let started = false;

export const ensureFonts = (): void => {
  if (started) {
    return;
  }
  started = true;
  const handle = delayRender('font loading (FONT_QC)');
  const css = FONTS.map(
    (f) => `@font-face {
  font-family: '${f.family}';
  font-style: normal;
  font-weight: ${f.weight};
  font-display: block;
  src: url('${staticFile(`fonts/${f.file}`)}') format('woff2');
}`
  ).join('\n');
  const style = document.createElement('style');
  style.textContent = css;
  document.head.appendChild(style);

  // load every face, then verify the family really resolved — a silent
  // fallback (serif) is the §33.1 failure mode this gate exists to block
  Promise.all(
    FONTS.map((f) =>
      document.fonts.load(`${f.weight} 16px "${f.family}"`, 'Terraform count 0123')
    )
  )
    .then(() => {
      const failed = FONTS.filter(
        (f) => !document.fonts.check(`${f.weight} 16px "${f.family}"`)
      ).map((f) => `${f.family} ${f.weight}`);
      if (failed.length > 0) {
        throw new Error(`FONT_QC = FAIL — fonts did not resolve: ${failed.join(', ')}. DO NOT RENDER.`);
      }
      continueRender(handle);
    })
    .catch((err: unknown) => {
      // surface the failure through the same delayRender handle so the
      // render errors out instead of producing a serif-fallback video
      delayRender(`FONT_QC = FAIL: ${(err as Error).message}`, {timeoutInMilliseconds: 30000});
      continueRender(handle);
    });
};