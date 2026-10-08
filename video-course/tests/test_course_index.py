"""Lab resolution — course_index.resolve_lab (short-command contract §2)."""
import course_index


LABS = [
    {"section": "section-01-foundations", "lab": "01-authentication-app-object",
     "path": "section-01-foundations/01-authentication-app-object", "number": 1},
    {"section": "section-01-foundations", "lab": "02-storage-account",
     "path": "section-01-foundations/02-storage-account", "number": 2},
    {"section": "section-01-foundations", "lab": "12-subnet-resource",
     "path": "section-01-foundations/12-subnet-resource", "number": 12},
    # section-02 after the 2026-09-26 global renumbering (26-50)
    {"section": "section-02-meta-arguments", "lab": "26-count-meta-argument",
     "path": "section-02-meta-arguments/26-count-meta-argument", "number": 26},
    {"section": "section-02-meta-arguments", "lab": "27-multiple-containers",
     "path": "section-02-meta-arguments/27-multiple-containers", "number": 27},
    {"section": "section-03-web-apps-and-databases", "lab": "51-web-app",
     "path": "section-03-web-apps-and-databases/51-web-app", "number": 51},
]


def test_prefix_resolves():
    assert course_index.resolve_lab("01", LABS)[0]["lab"] == "01-authentication-app-object"


def test_bare_number_resolves():
    assert course_index.resolve_lab("2", LABS)[0]["lab"] == "02-storage-account"


def test_exact_name_resolves():
    hits = course_index.resolve_lab("12-subnet-resource", LABS)
    assert hits[0]["lab"] == "12-subnet-resource"


def test_all_returns_every_lab():
    assert course_index.resolve_lab("all", LABS) == LABS


def test_ambiguous_raises():
    # "0" matches every lab number/name and is not a unique prefix
    try:
        course_index.resolve_lab("0", LABS)
        assert False, "expected SystemExit"
    except SystemExit:
        pass


def test_unknown_raises():
    try:
        course_index.resolve_lab("99", LABS)
        assert False, "expected SystemExit"
    except SystemExit:
        pass


# --- section-aware resolution (2026-09-26 renumbering; plan Phase A1) ---

S01 = "section-01-foundations"
S02 = "section-02-meta-arguments"


def test_global_number_across_sections():
    # "26" is section-02's first lab under the global numbering
    assert course_index.resolve_lab("26", LABS)[0]["lab"] == "26-count-meta-argument"
    assert course_index.resolve_lab("51", LABS)[0]["lab"] == "51-web-app"


def test_exact_path_match():
    hits = course_index.resolve_lab("section-03-web-apps-and-databases/51-web-app", LABS)
    assert len(hits) == 1 and hits[0]["number"] == 51


def test_exact_path_unknown_raises():
    try:
        course_index.resolve_lab("section-02-meta-arguments/01-count-meta-argument", LABS)
        assert False, "expected SystemExit (public-era path no longer local)"
    except SystemExit:
        pass


def test_section_scoped_number():
    hits = course_index.resolve_lab("26", LABS, section=S02)
    assert len(hits) == 1 and hits[0]["lab"] == "26-count-meta-argument"


def test_section_scoped_unknown_ref_raises():
    # "01" is stale for section-02 after renumbering — fail loudly, never guess
    try:
        course_index.resolve_lab("01", LABS, section=S02)
        assert False, "expected SystemExit"
    except SystemExit:
        pass


def test_section_scoped_ambiguous_raises():
    # "2" alone is ambiguous inside section-01 (02- prefix and number 2 both hit)
    course_index.resolve_lab("02", LABS, section=S01)  # unique prefix -> fine
    try:
        course_index.resolve_lab("26", LABS, section="section-99-none")
        assert False, "expected SystemExit"
    except SystemExit:
        pass


def test_bare_stale_number_falls_back_to_manifest(capsys):
    # legacy path, pre-renamed layout (still the PUBLIC repo's naming):
    # "1" matches 01- prefixes in two sections -> manifest number decides, loudly.
    public_style = [
        {"section": S01, "lab": "01-authentication-app-object",
         "path": f"{S01}/01-authentication-app-object", "number": 1},
        {"section": S02, "lab": "01-count-meta-argument",
         "path": f"{S02}/01-count-meta-argument", "number": 26},
    ]
    hits = course_index.resolve_lab("1", public_style)
    assert hits[0]["lab"] == "01-authentication-app-object"
    assert "warning" in capsys.readouterr().err.lower()