#!/usr/bin/env python3
"""Backward-compat wrapper: the canonical TTS tool is now generate_voice.py
(Edge TTS is the free default; MiniMax is optional). This wrapper keeps the
old `minimax_tts.py <episode>` command working; it forwards to generate_voice
and warns that the name is deprecated. Existing command names stay working
(instruction §43)."""
import os
import sys
import warnings

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.argv[0] = os.path.join(HERE, "generate_voice.py")

print("NOTE: minimax_tts.py is a compatibility wrapper — the canonical tool "
      "is generate_voice.py (edge-tts default, MiniMax optional).",
      file=sys.stderr)

import generate_voice  # noqa: E402

generate_voice.main()