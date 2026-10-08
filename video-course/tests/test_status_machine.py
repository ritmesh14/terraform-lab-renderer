"""Status machine — one-way DRAFT..FINAL, legacy tagging (instruction §27/§28)."""
import status_machine as sm


def test_forward_transitions_legal():
    for a, b in zip(sm.ORDER, sm.ORDER[1:]):
        assert sm.can_transition(a, b)


def test_backward_transitions_illegal():
    assert not sm.can_transition("VALIDATED", "DRAFT")
    assert not sm.can_transition("RENDERED", "APPROVED")
    assert not sm.can_transition("FINAL", "DRAFT")


def test_same_rank_ok():
    assert sm.can_transition("VALIDATED", "VALIDATED")


def test_max_of():
    assert sm.max_of("DRAFT", "RENDERED") == "RENDERED"
    assert sm.max_of("FINAL", "RENDERED") == "FINAL"


def test_legacy_rendered_tagged():
    rec = {"status": "RENDERED"}
    rec = sm.migrate_legacy(rec)
    assert rec["legacy_pipeline"] is True
    assert rec["needs_revalidation"] is True
    assert rec["pipeline"] == "legacy"


def test_new_pipeline_not_tagged():
    rec = {"status": "RENDERED", "pipeline": "new"}
    rec = sm.migrate_legacy(rec)
    assert "legacy_pipeline" not in rec


def test_set_status_writes_and_upgrades(tmp_path):
    pr = {"episodes": {"02-storage-account": {"status": "DRAFT"}}}
    ep = {"path": "02-storage-account"}
    sm.save_progress(tmp_path / "p.json", pr)
    sm.set_status(pr, str(tmp_path / "p.json"), ep, "VALIDATED")
    assert sm.get_status(pr, ep) == "VALIDATED"
    assert pr["episodes"]["02-storage-account"]["pipeline"] == "new"
    reloaded = sm.load_progress(tmp_path / "p.json")
    assert sm.get_status(reloaded, ep) == "VALIDATED"


def test_downgrade_refused_and_untouched(tmp_path):
    pr = {"episodes": {"x": {"status": "RENDERED"}}}
    ep = {"path": "x"}
    sm.save_progress(tmp_path / "p.json", pr)
    try:
        sm.set_status(pr, str(tmp_path / "p.json"), ep, "DRAFT")
        assert False, "expected SystemExit on downgrade"
    except SystemExit:
        pass
    assert sm.get_status(pr, ep) == "RENDERED"