// Render EXACT source-code slices as HTML via Shiki (never retyped, never LLM-drawn).
// Output HTML is screenshot headlessly (Edge/Chrome) into assets/code/*.png.
//
// Usage:
//   node render_code_html.mjs <source-file> <start-line> <end-line> <out.html> [highlight-lines-csv]
// Highlight line numbers are ABSOLUTE (source file) line numbers.
import {codeToHtml} from 'shiki';
import fs from 'node:fs';

const [,, sourceFile, startArg, endArg, outFile, hlArg] = process.argv;
const start = parseInt(startArg, 10);
const end = parseInt(endArg, 10);
if (!sourceFile || !start || !end || !outFile) {
  console.error('usage: render_code_html.mjs <source> <start> <end> <out.html> [highlight-csv]');
  process.exit(1);
}

const allLines = fs.readFileSync(sourceFile, 'utf8').split(/\r?\n/);
const code = allLines.slice(start - 1, end).join('\n');
const highlight = (hlArg || '').split(',').filter(Boolean).map(Number);

const highlighted = await codeToHtml(code, {lang: 'terraform', theme: 'github-dark'});

// tag highlighted lines (shiki emits one <span class="line"> per source line)
let n = 0;
const marked = highlighted.replace(/<span class="line">/g, () => {
  n += 1;
  const abs = start + n - 1;
  return highlight.includes(abs)
    ? '<span class="line hl">'
    : '<span class="line">';
});

const html = `<!doctype html>
<html><head><meta charset="utf-8"><style>
  html, body { margin: 0; padding: 0; background: #0B1120; }
  .wrap { padding: 56px 72px; }
  pre, code {
    background: transparent !important;
    font-family: "Cascadia Code", "JetBrains Mono", Consolas, monospace !important;
    font-size: 34px !important;
    line-height: 1.5 !important;
    margin: 0 !important;
    counter-reset: line;
  }
  .line { display: inline-block; width: 100%; }
  .line.hl {
    background: rgba(0, 120, 212, 0.22);
    border-left: 6px solid #0078D4;
    padding-left: 14px;
    box-sizing: border-box;
    width: calc(100% - 20px);
  }
</style></head>
<body><div class="wrap">${marked}</div></body></html>`;

fs.writeFileSync(outFile, html);
console.log(`-> ${outFile} (lines ${start}-${end}, ${end - start + 1} lines, ${highlight.length} highlighted)`);