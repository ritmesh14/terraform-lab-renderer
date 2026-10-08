"""Manifest + leak scan + terminal sanitizer (instruction §7/§20/§24)."""
import build_manifest as bm
import normalize_terminal_output as nto
import sync_ci_inputs as sc


def test_collect_files_ext_and_names(tmp_path):
    (tmp_path / "main.tf").write_text("a = 1")
    (tmp_path / "README.md").write_text("x")
    (tmp_path / "terraform.tfvars.example").write_text("x")
    (tmp_path / "notes.txt").write_text("x")
    (tmp_path / "terraform.tfvars.example").touch()
    got = {f.split("\\")[-1].split("/")[-1] for f in
           bm.collect_files(str(tmp_path), (".tf", ".tfvars.example", ".tftest.hcl"),
                            ("README.md",))}
    assert "main.tf" in got
    assert "README.md" in got
    assert "notes.txt" not in got


def test_category_for(tmp_path):
    assert bm.category_for("labs/x/main.tf") == "terraform"
    assert bm.category_for("labs/x/README.md") == "documentation"
    assert bm.category_for("labs/x/terraform.tfvars.example") == "variables_example"
    assert bm.category_for("labs/x/tests/x.tftest.hcl") == "tests"
    assert bm.category_for("labs/x/.github/workflows/ci.yml") == "automation"
    assert bm.category_for("labs/x/other.bin") == "other"


def test_sha256_stable():
    a = tmp_file = None
    import hashlib, os, tempfile
    d = tempfile.mkdtemp()
    p1, p2 = os.path.join(d, "1"), os.path.join(d, "2")
    open(p1, "w").write("same")
    open(p2, "w").write("same")
    assert bm.sha256(p1) == bm.sha256(p2) == hashlib.sha256(b"same").hexdigest()


def test_leak_scan_finds_internal_paths(tmp_path):
    bad = tmp_path / "notes.md"
    # path built at runtime so the committed fixture never embeds a real path
    bad.write_text("the lab lives at " + "E:" + "\\" + "labs" + "\\x",
                   encoding="utf-8")
    ok = tmp_path / "clean.md"
    ok.write_text("github.com/RIT-MESH is fine", encoding="utf-8")
    found = sc.scan_leakage([str(bad), str(ok)], str(tmp_path))
    assert len(found) == 1 and "notes.md" in found[0]


def test_leak_scan_ignores_binary(tmp_path):
    binf = tmp_path / "x.bin"
    binf.write_bytes(("E:" + "\\" + "labs").encode() + b"\xff\xfe")
    assert sc.scan_leakage([str(binf)], str(tmp_path)) == []


def test_terminal_normalize_strips_secrets_and_paths():
    raw = ("\x1b[32mok\x1b[0m subscription: 12345678-1234-1234-1234-123456789012 "
           "password=hunter2 \x1b]0;title\x07\n"
           "C:\\Users\\someone\\app.log\n")
    out = nto.normalize(raw)
    assert "\x1b" not in out
    assert "<guid>" in out
    assert "<redacted>" in out
    assert "rites" not in out
    assert "title" not in out  # OSC sequence gone


def test_terminal_normalize_keeps_meaningful_text():
    assert nto.normalize("terraform plan: 1 to add\n\n\n") == "terraform plan: 1 to add\n"

def test_render_parts_srt_split_roundtrip(tmp_path):
    """render_parts SRT helpers: parse -> split -> shift-to-zero -> parse."""
    import render_parts as rp
    srt = tmp_path / "episode.srt"
    srt.write_text(
        "1\n00:00:01,000 --> 00:00:02,000\nhello\n\n"
        "2\n00:00:05,000 --> 00:00:06,000\nworld\n\n", encoding="utf-8")
    cues = rp.parse_srt(str(srt))
    assert len(cues) == 2
    # split at 4.0s: part1 keeps cue 1; part2 shifts cue 2 to zero
    split_sec = 4.0
    part1 = [c for c in cues if c[0] < split_sec and c[1] <= split_sec + 0.01]
    part2 = [(a - split_sec, b - split_sec, t) for a, b, t in cues
             if a >= split_sec - 0.01]
    assert len(part1) == 1 and part1[0][2] == "hello"
    assert len(part2) == 1 and part2[0][0] == 1.0
    out = tmp_path / "part2.srt"
    rp.write_srt(str(out), part2)
    again = rp.parse_srt(str(out))
    assert again[0][0] == 1.0 and again[0][2] == "world"
