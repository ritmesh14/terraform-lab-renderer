"""Part 1 duration policy (VIDEO-MAKING-PROCESS.md, updated 2026-10-31):
the AI-generated instructional portion must MEASURE 4:00-10:00, using the
exact split boundary render_parts.py uses (the LAST scene's scene_start_frame
— the thank-you outro is the final scene; the manually inserted demo and the
outro are excluded). Blocking post-audio in validate_episode (G3) and in
quality_check.py; never satisfied by padding/trimming/speeding audio.
"""
import json
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TOOLS = os.path.join(os.path.dirname(HERE), "tools")

NEXT = ("Now that we understand how this Terraform configuration works, "
        "in the next part of this video, we'll move to a real-world demo "
        "and deploy it in Microsoft Azure.")


def write_episode(tmp_path, part1_sec, fps=30):
    """Minimal episode fixture. Part 1 = S001+S002+S003 (the S004 outro's
    scene_start_frame is the render_parts.py split boundary). S001 absorbs
    the slack; S002/S003 get realistic 13s windows so WPM density passes."""
    ep = tmp_path / str(part1_sec)
    (ep / "writing").mkdir(parents=True)
    (ep / "timing").mkdir(parents=True)
    scenes = [
        {"id": "S001", "type": "CONCEPT",
         "narration": "In this lesson we create a resource group and a "
                      "storage account in Azure and link them together."},
        {"id": "S002", "type": "RECAP",
         "narration": "We covered the resource group.",
         "points": ["resource group"]},
        {"id": "S003", "type": "NEXT", "narration": NEXT},
        {"id": "S004", "type": "TITLE", "narration": "Thanks for watching."},
    ]
    (ep / "writing" / "scenes.json").write_text(
        json.dumps({"scenes": scenes}), encoding="utf-8")
    d2 = d3 = 13.0
    s1 = part1_sec - d2 - d3
    assert s1 > 0
    f1, f2, f3 = (round(s1 * fps), round(d2 * fps), round(d3 * fps))
    timed = [
        {"id": "S001", "scene_start_frame": 0,
         "total_frames": f1, "duration_sec": s1},
        {"id": "S002", "scene_start_frame": f1,
         "total_frames": f2, "duration_sec": d2},
        {"id": "S003", "scene_start_frame": f1 + f2,
         "total_frames": f3, "duration_sec": d3},
        {"id": "S004", "scene_start_frame": f1 + f2 + f3,
         "total_frames": 2 * fps, "duration_sec": 2.0},
    ]
    (ep / "timing" / "timed-scenes.json").write_text(json.dumps({
        "fps": fps, "scenes": timed,
        "total_duration_frames": f1 + f2 + f3 + 2 * fps}), encoding="utf-8")
    return ep


def run_tool(tool, ep):
    p = subprocess.run([sys.executable, os.path.join(TOOLS, tool), str(ep)],
                       capture_output=True, text=True, encoding="utf-8")
    return p


def validate(part1_sec, tmp_path):
    ep = write_episode(tmp_path, part1_sec)
    p = run_tool("validate_episode.py", ep)
    report = json.loads((ep / "validation" / "validation.json")
                        .read_text(encoding="utf-8"))
    return p.returncode, report


def test_part1_in_range_passes(tmp_path):
    code, report = validate(340, tmp_path)
    assert code == 0, report["fails"]
    assert report["status"] == "pass", report["fails"]
    g3 = report["gates"]["gate3_learning_experience"]
    assert g3["part1_sec"] == 340
    assert g3["part1_target_sec"] == [240, 600]


def test_part1_too_short_fails(tmp_path):
    code, report = validate(86, tmp_path)
    assert code == 1
    assert report["status"] == "fail"
    assert any("Part 1 (instructional) measured 86s" in f
               for f in report["fails"])
    assert report["gates"]["gate3_learning_experience"]["part1_sec"] == 86


def test_part1_too_long_fails(tmp_path):
    code, report = validate(660, tmp_path)
    assert code == 1
    assert report["status"] == "fail"
    assert any("Part 1 (instructional) measured 660s" in f
               for f in report["fails"])


def test_part1_boundaries_pass(tmp_path):
    # 4:00 and 10:00 exactly are inside the band (inclusive)
    for edge in (240, 600):
        code, report = validate(edge, tmp_path)
        assert not any("Part 1 (instructional)" in f
                       for f in report["fails"]), (edge, report["fails"])


# ------------------------------ quality_check -------------------------------

def synth_mp4(path, sec):
    """Deterministic synthetic episode.mp4 (h264+aac, 1920x1080@30)."""
    subprocess.run([
        "ffmpeg", "-y", "-v", "error",
        "-f", "lavfi", "-i", "color=c=0x0B1120:s=1920x1080:r=30",
        "-f", "lavfi", "-i", "sine=frequency=440:sample_rate=44100",
        "-t", str(sec), "-c:v", "libx264", "-pix_fmt", "yuv420p",
        "-c:a", "aac", "-shortest", str(path)],
        check=True, capture_output=True, text=True)


def qc_check_entry(ep):
    run_tool("quality_check.py", ep)
    report = json.loads((ep / "validation" / "quality-check.json")
                        .read_text(encoding="utf-8"))
    entry = next(c for c in report["checks"]
                 if c["check"] == "part1 duration 4:00-10:00")
    return entry


def test_quality_check_part1_out_of_range(tmp_path):
    ep = write_episode(tmp_path, 60)   # part1 = 60s < 4:00
    (ep / "final").mkdir()
    synth_mp4(ep / "final" / "episode.mp4", 62)
    entry = qc_check_entry(ep)
    assert entry["passed"] is False
    assert "60.0s" in entry["detail"]


def test_quality_check_part1_in_range(tmp_path):
    ep = write_episode(tmp_path, 300)
    (ep / "final").mkdir()
    synth_mp4(ep / "final" / "episode.mp4", 302)
    entry = qc_check_entry(ep)
    assert entry["passed"] is True