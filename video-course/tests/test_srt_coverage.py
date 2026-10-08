"""SRT — word-coverage gate + never-drop-words cue construction (§5/§6)."""
import json

import validate_srt_coverage as vc


SCENES = [
    {"id": "S001", "type": "TITLE",
     "narration": "Welcome to the Terraform Azure labs. Today we deploy a storage account."},
    {"id": "S002", "type": "CODE",
     "narration": "The resource block defines an azurerm storage account.",
     "steps": [
         {"narration": "The resource block defines an azurerm storage account."},
         {"narration": "Account tier is standard and replication is LRS."},
     ]},
]

SRT_FULL = """1
00:00:00,000 --> 00:00:05,000
Welcome to the Terraform Azure labs. Today we deploy a storage account.

2
00:00:05,000 --> 00:00:09,000
The resource block defines an azurerm storage account.

3
00:00:09,000 --> 00:00:12,000
Account tier is standard and replication is LRS.
"""

SRT_DROPPED = """1
00:00:00,000 --> 00:00:05,000
Welcome to the Terraform Azure labs. Today we deploy a storage account.
"""


def make_ep(tmp_path, srt_text):
    ep = tmp_path / "ep"
    (ep / "writing").mkdir(parents=True)
    (ep / "final").mkdir(parents=True)
    (ep / "writing" / "scenes.json").write_text(
        json.dumps({"scenes": SCENES}), encoding="utf-8")
    (ep / "final" / "episode.srt").write_text(srt_text, encoding="utf-8")
    return ep


def test_steps_are_the_spoken_text():
    txt = vc.spoken_text(SCENES)
    assert "Welcome to the Terraform" in txt
    # step narration only once — the top-level CODE narration is not spoken twice
    assert txt.count("defines an azurerm storage account") == 1


def test_coverage_full_is_100():
    words = vc.normalize("the cat sat on the mat")
    assert vc.coverage(words, vc.normalize("the cat sat on the mat")) == 100.0


def test_coverage_multiset_not_set():
    # one "cat" in narration, two "cats"... multiset: partial counts once only
    assert vc.coverage(["cat", "cat"], ["cat"]) == 50.0


def test_validate_passes_when_everything_is_carried(tmp_path):
    report, fails = vc.validate(make_ep(tmp_path, SRT_FULL), scenes=SCENES)
    assert fails == []
    assert report["status"] == "pass"


def test_validate_fails_when_words_dropped(tmp_path):
    report, fails = vc.validate(make_ep(tmp_path, SRT_DROPPED), scenes=SCENES)
    assert fails and any("coverage" in f for f in fails)


def test_tag_never_leaks_into_srt(tmp_path):
    leak = SRT_FULL.replace("Welcome to", "<#1.5#>Welcome to")
    ep = make_ep(tmp_path, leak)
    report, fails = vc.validate(ep, scenes=SCENES)
    assert any("leak" in f for f in fails)


def test_overlapping_cues_fail(tmp_path):
    bad = """1
00:00:00,000 --> 00:00:05,000
Welcome to the Terraform Azure labs.

2
00:00:04,000 --> 00:00:09,000
The resource block defines an azurerm storage account.

3
00:00:09,000 --> 00:00:12,000
Account tier is standard and replication is LRS.
"""
    ep = make_ep(tmp_path, bad)
    report, fails = vc.validate(ep, scenes=SCENES)
    assert any("overlap" in f for f in fails)

def test_cues_never_exceed_wrap_capacity():
    """Regression: a duration-capped cue could carry ~90 chars that greedy-wrap
    to 3 lines; the writer's [:max_lines] then silently dropped the last line's
    words (SRT coverage 98.8-99.5% on CI). cues_from_words must flush on real
    wrap fit, so every cue fits max_lines at write time."""
    import generate_srt as gs
    style = {"max_lines": 2, "chars_per_line": [35, 45], "segment_sec": [1.5, 6]}
    # 9 words x 9 chars = 89 chars (<= 2*45) but wraps to 3 lines at 45/line;
    # total duration 5.4s (< 6s cap) so only the wrap-fit check can flush
    words = [{"text": "a" * 9, "offset_ms": i * 600, "duration_ms": 600}
             for i in range(9)]
    cues = gs.cues_from_words(words, style)
    joined = " ".join(t for _, _, t in cues)
    assert all(("a" * 9) == w for w in joined.split())  # every word survives
    for _, _, t in cues:
        assert len(gs.split_cues(t, 45)) <= 2  # writer never truncates
