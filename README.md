# terraform-lab-renderer

CI render farm for the Terraform-on-Azure video course. Rendering only — the
course home (labs, docs) lives at
[RIT-MESH/Terraform-Azure-Labs-and-Case_Studies](https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies).

## What this repo does

`video-course/output/<section>/<lab>/writing/` episode sources + asset specs
are pushed here (never rendered media), and
`.github/workflows/render-course-video.yml` renders each episode on
`ubuntu-latest`: edge-TTS narration (free, no API key) → loudness normalize −16
LUFS → word-timing → multi-cue SRT (≥ 99.5% coverage) → Remotion → FFmpeg → QC
→ two-part split (`part1-main` + `part2-thankyou`). Deliverables come back as
workflow artifacts and are copied into the production tree by the renderer.

## Usage

    # dispatch a render for one lab
    gh workflow run render-course-video.yml \
      -f lab=26 -f section=section-02-meta-arguments

    # download the artifact (run id from the workflow run page)
    gh run download <run-id>

Rendered video is only ever published as an artifact; nothing is committed to
`main`.