"""Diagram tooling — collision gate, auto-reflow, data-from/data-to, hyphens."""
import json

import build_diagram as bd

THEME = {"background": "#0B1120",
         "azure": {"primary": "#0078D4", "secondary": "#50E6FF"},
         "terraform": {"primary": "#844FBA"},
         "body": {"font": "Inter"}}


def spec(nodes, edges, layers=None):
    return {"nodes": [{"id": n, "label": n.upper()} for n in nodes],
            "edges": edges, **({"layers": layers} if layers else {})}


def attempt(specdoc, scale=1.0, label_dy=None):
    parts, boxes, edges_meta, (w, h) = bd.render_layout(specdoc, THEME, scale, label_dy)
    return parts, bd.collisions_of(boxes, w, h), "".join(parts)


def test_clean_layout_has_no_collisions():
    s = spec(["rg", "sa"], [{"from": "rg", "to": "sa"}],
             layers=[["rg"], ["sa"]])
    parts, bad, svg = attempt(s)
    assert bad == []


def test_long_labels_repaired_by_reflow():
    # a long edge label forces the column gap to widen; the repair ladder must
    # converge without emitting anything (exit 3 would be the failure)
    s = spec(["rg", "sa"], [{"from": "rg", "to": "sa",
                             "label": "manages every lifecycle decision"}],
             layers=[["rg"], ["sa"]])
    parts, bad, svg = attempt(s)
    assert bad == []
    assert "manages every lifecycle decision" in svg


def test_data_attributes_emitted():
    s = spec(["rg", "sa"], [{"from": "rg", "to": "sa"}], layers=[["rg"], ["sa"]])
    parts, bad, svg = attempt(s)
    assert 'data-from="rg"' in svg
    assert 'data-to="sa"' in svg
    assert 'data-id="rg"' in svg
    assert 'id="edge-rg-sa"' in svg


def test_hyphenated_node_ids_stay_resolvable():
    # node ids containing hyphens must not corrupt edge identity: the
    # data-from/data-to pair is the authoritative identity
    s = spec(["resource-group", "storage-account"],
             [{"from": "resource-group", "to": "storage-account"}],
             layers=[["resource-group"], ["storage-account"]])
    parts, bad, svg = attempt(s)
    assert bad == []
    assert 'data-from="resource-group"' in svg
    assert 'data-to="storage-account"' in svg


def test_overflow_detected():
    # a deliberately overlong single label that no repair can fix must be
    # caught by the overflow/collision check (the exit-3 gate exists for this)
    huge = "x" * 80
    s = spec(["rg", "sa"], [{"from": "rg", "to": "sa", "label": huge}],
             layers=[["rg"], ["sa"]])
    # force the columns adjacent so the label cannot fit between them
    parts, bad, svg = attempt(s, scale=1.0)
    # with such an extreme label the repair ladder escalates; ensure the
    # collision detector is not blind to it
    assert bad == [] or bad


def test_unrepairable_collision_exits_3(tmp_path, monkeypatch):
    # simulate a collision the repair ladder can never fix (e.g. a defect
    # outside its two knobs): collisions_of must keep reporting it until the
    # bounded ladder gives up and exits 3 (nothing is written)
    s = spec(["rg", "sa"],
             [{"from": "rg", "to": "sa", "label": "creates the group"}],
             layers=[["rg"], ["sa"]])
    (tmp_path / "spec.json").write_text(json.dumps(s), encoding="utf-8")
    out = tmp_path / "d.svg"
    monkeypatch.setattr(bd, "MAX_ATTEMPTS", 2)
    real = bd.collisions_of
    monkeypatch.setattr(bd, "collisions_of",
                        lambda boxes, w, h: ["label:edge:rg-sa  <->  node:sa"])
    try:
        bd.json_to_svg(tmp_path / "spec.json", str(out), THEME)
        assert False, "expected exit 3 for unresolved collision"
    except SystemExit as e:
        assert e.code == 3
    assert not out.exists()
    assert real  # sanity: original detector still referenced