#!/usr/bin/env python3
"""Render an original, dependency-free ambient loop for Word Tiles."""
import math
import sys
import wave
from array import array
from pathlib import Path

RATE = 22050
BEAT = 0.75
SECONDS = 64 * BEAT
OUTPUT = Path(__file__).resolve().parents[1] / "godot-project/audio/garden_loop.wav"


def add_note(mix, midi, start, duration, gain, attack, release, bright=False):
    frequency = 440.0 * 2.0 ** ((midi - 69) / 12.0)
    first = round(start * RATE)
    samples = min(round(duration * RATE), len(mix) - first)
    for index in range(max(0, samples)):
        elapsed = index / RATE
        remaining = (samples - 1 - index) / RATE
        envelope = min(1.0, elapsed / attack, remaining / release)
        envelope = max(0.0, envelope)
        phase = math.tau * frequency * elapsed
        if bright:
            wave_value = (math.sin(phase) + 0.12 * math.sin(phase * 2.0))
            envelope *= math.exp(-2.6 * elapsed)
        else:
            wave_value = math.sin(phase) + 0.05 * math.sin(phase * 2.0)
            envelope *= 0.94 + 0.06 * math.cos(math.tau * 0.3 * elapsed)
        mix[first + index] += wave_value * gain * envelope


def main():
    mix = array("f", [0.0]) * round(SECONDS * RATE)
    chords = [(48, 52, 55), (45, 48, 52), (41, 45, 48), (43, 47, 50)] * 2
    melody = [72, 76, None, 79, 76, None, 74, 72,
              69, None, 72, 76, 72, None, 69, None,
              69, 72, None, 77, 76, None, 72, 69,
              67, None, 71, 74, 79, None, 74, None,
              76, None, 79, 84, 79, 76, None, 72,
              76, 72, None, 69, 72, None, 76, None,
              77, None, 76, 72, 69, None, 72, None,
              74, 71, None, 67, 71, None, 72, None]
    for chord_index, chord in enumerate(chords):
        start = chord_index * 8 * BEAT
        for midi in chord:
            add_note(mix, midi, start, 8 * BEAT, 0.047, 0.25, 0.9)
        add_note(mix, chord[0] - 12, start, 7.8 * BEAT, 0.025, 0.3, 1.0)
    for beat, midi in enumerate(melody):
        if midi is not None:
            add_note(mix, midi, beat * BEAT, 1.4 * BEAT, 0.095, 0.012, 0.18, True)
    peak = max(abs(value) for value in mix)
    scale = 0.65 * 32767 / max(peak, 0.001)
    pcm = array("h", (round(value * scale) for value in mix))
    if sys.byteorder != "little":
        pcm.byteswap()
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    temporary = OUTPUT.with_suffix(".wav.tmp")
    with wave.open(str(temporary), "wb") as stream:
        stream.setnchannels(1)
        stream.setsampwidth(2)
        stream.setframerate(RATE)
        stream.writeframes(pcm.tobytes())
    temporary.replace(OUTPUT)
    print(f"Generated {SECONDS:.0f}s / {RATE} Hz / mono PCM16 -> {OUTPUT}")


if __name__ == "__main__":
    main()
