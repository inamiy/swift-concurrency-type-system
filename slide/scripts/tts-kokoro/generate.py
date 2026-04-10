#!/usr/bin/env python3
"""Generate speech audio from a transcript text file using Kokoro TTS.

Usage:
    python generate.py <input.txt> [output.wav] [--voice VOICE] [--speed SPEED] [--lang LANG]

Requirements:
    brew install espeak          # macOS G2P backend
    pip install -r requirements.txt
"""

import argparse
import re
import sys
from pathlib import Path

import numpy as np
import soundfile as sf
from kokoro import KPipeline


def strip_non_speech(text: str) -> str:
    """Remove non-speech elements from transcript for TTS."""
    # Remove HTML comments (single-line and multi-line)
    text = re.sub(r"<!--.*?-->", "", text, flags=re.DOTALL)
    # Remove timestamp lines like "00:30 (+0.5 min)" or "2:30 (+1 min)"
    text = re.sub(r"^\d{1,2}:\d{2}\s*\(.*?\)\s*$", "", text, flags=re.MULTILINE)
    lines = []
    for line in text.splitlines():
        stripped = line.strip()
        # Skip markdown headings
        if stripped.startswith("#"):
            continue
        # Skip slide separators
        if stripped == "---":
            continue
        # Skip markdown formatting artifacts (bold/italic markers only)
        if re.match(r"^[\*_`]+$", stripped):
            continue
        lines.append(line)
    # Collapse multiple blank lines into one
    result = re.sub(r"\n{3,}", "\n\n", "\n".join(lines))
    return result.strip()


def main():
    parser = argparse.ArgumentParser(description="Generate audio from transcript using Kokoro TTS")
    parser.add_argument("input", help="Input transcript text file")
    parser.add_argument("output", nargs="?", default=None, help="Output wav file (default: <input>.wav)")
    parser.add_argument("--voice", default="af_heart", help="Voice name (default: af_heart)")
    parser.add_argument("--speed", type=float, default=1.0, help="Speech speed (default: 1.0)")
    parser.add_argument("--lang", default="a", help="Language code: a=en-us, b=en-gb, j=ja (default: a)")
    parser.add_argument("--pause", type=float, default=0.5, help="Pause between paragraphs in seconds (default: 0.5)")
    args = parser.parse_args()

    input_path = Path(args.input)
    if not input_path.exists():
        print(f"Error: {input_path} not found", file=sys.stderr)
        sys.exit(1)

    output_path = Path(args.output) if args.output else input_path.with_suffix(".wav")

    raw_text = input_path.read_text(encoding="utf-8").strip()
    if not raw_text:
        print("Error: input file is empty", file=sys.stderr)
        sys.exit(1)

    text = strip_non_speech(raw_text)
    if not text:
        print("Error: no speakable text after stripping comments/headings", file=sys.stderr)
        sys.exit(1)

    print(f"Input:  {input_path}")
    print(f"Output: {output_path}")
    print(f"Voice:  {args.voice}, Speed: {args.speed}, Lang: {args.lang}")
    print()

    pipeline = KPipeline(lang_code=args.lang)

    sample_rate = 24000
    pause_samples = int(args.pause * sample_rate)
    silence = np.zeros(pause_samples, dtype=np.float32)

    segments = []
    generator = pipeline(text, voice=args.voice, speed=args.speed, split_pattern=r"\n+")

    for i, (graphemes, phonemes, audio) in enumerate(generator):
        if audio is not None:
            print(f"  [{i:03d}] {graphemes[:60]}...")
            segments.append(audio)
            segments.append(silence)

    if not segments:
        print("Error: no audio generated", file=sys.stderr)
        sys.exit(1)

    # Remove trailing silence
    if len(segments) > 1:
        segments.pop()

    combined = np.concatenate(segments)
    sf.write(str(output_path), combined, sample_rate)

    duration = len(combined) / sample_rate
    print(f"\nDone: {output_path} ({duration:.1f}s / {duration/60:.1f}min)")


if __name__ == "__main__":
    main()
