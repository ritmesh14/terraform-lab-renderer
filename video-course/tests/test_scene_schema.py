"""Scene schema — per-type rules, NEXT verbatim, demo gate, leak scan (§30/§41)."""
import json

import validate_scene_schema as vs


NEXT = ("Now that we understand how this Terraform configuration works, "
        "in the next part of this video, we'll move to a real-world demo "
        "and deploy it in Microsoft Azure.")


def run(tmp_path, scenes):
    ep = tmp_path / "ep"
    (ep / "writing").mkdir(parents=True)
    (ep / "writing" / "scenes.json").write_text(
        json.dumps({"scenes": scenes}), encoding="utf-8")
    result, fails = vs.validate_scene_scenes(str(ep))
    return result, fails


def test_happy_episode_passes(tmp_path):
    scenes = [
        {"id": "S001", "type": "TITLE", "narration": "Welcome."},
        {"id": "S002", "type": "RECAP",
         "narration": "Today we covered resource groups and storage accounts.",
         "points": ["Resource groups", "Storage accounts"]},
        {"id": "S003", "type": "NEXT", "narration": NEXT},
        {"id": "S004", "type": "PORTAL", "narration": "Here it is in Azure.",
         "demo": True},
    ]
    result, fails = run(tmp_path, scenes)
    assert result["status"] == "pass", fails
    assert result["demo_gate"] == "pass"


def test_demo_gate_pending_blocks_nothing_but_is_reported(tmp_path):
    scenes = [
        {"id": "S001", "type": "RECAP", "narration": "That was the recap.",
         "points": ["one thing"]},
        {"id": "S002", "type": "NEXT", "narration": NEXT},
    ]
    result, fails = run(tmp_path, scenes)
    # non-blocking pre-demo: status stays pass, gate says pending
    assert result["status"] == "pass"
    assert result["demo_gate"] == "pending"
    assert any(f.startswith("DEMO-GATE") for f in fails)


def test_demo_before_next_does_not_count(tmp_path):
    scenes = [
        {"id": "S001", "type": "PORTAL", "narration": "mock", "demo": True},
        {"id": "S002", "type": "NEXT", "narration": NEXT},
    ]
    result, fails = run(tmp_path, scenes)
    assert result["demo_gate"] == "pending"


def test_next_must_be_verbatim(tmp_path):
    bad = NEXT.replace("real-world demo", "hands-on demo")
    result, fails = run(tmp_path, [{"id": "S001", "type": "NEXT", "narration": bad}])
    assert result["status"] == "fail"
    assert any("verbatim" in f for f in fails)


def test_recap_and_next_required(tmp_path):
    result, fails = run(tmp_path, [{"id": "S001", "type": "TITLE", "narration": "hi"}])
    assert any("no NEXT scene" in f for f in fails)
    assert any("no RECAP scene" in f for f in fails)


def test_code_active_lines_out_of_bounds(tmp_path):
    scenes = [{
        "id": "S001", "type": "CODE", "source_file": "main.tf",
        "start_line": 10, "end_line": 20, "asset": "assets/code/x.png",
        "steps": [{"narration": "look at line 30", "active_lines": [30]}],
    }]
    result, fails = run(tmp_path, scenes)
    assert any("active_lines 30 outside" in f for f in fails)


def test_empty_narration_fails(tmp_path):
    result, fails = run(tmp_path, [{"id": "S001", "type": "TITLE", "narration": "   "}])
    assert any("empty narration" in f for f in fails)


def test_sequential_ids_required(tmp_path):
    scenes = [{"id": "S002", "type": "TITLE", "narration": "x"}]
    result, fails = run(tmp_path, scenes)
    assert any("sequential" in f for f in fails)


def test_local_path_leak_fails(tmp_path):
    # path built at runtime so the committed fixture never embeds a real path
    internal = "E:" + "\\" + "labs" + "\\" + "section-01"
    result, fails = run(tmp_path, [
        {"id": "S001", "type": "TITLE", "narration": "see " + internal}])
    assert any("leaked" in f for f in fails)