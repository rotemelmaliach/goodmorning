"""Generates the alarm sound library into App/GoodMorning/Sounds.

Every sound is synthesized here from scratch (no samples, so nothing to license). Pure standard
library; run with:  python tools/make_sounds.py

For each sound it writes two files:
  <name>.wav        a seamless 16 s loop the app plays, with its own volume ramp
  <name>-alarm.wav  the loop with a slow fade-in baked in, played by the system alarm

File names must match AlarmSound.fileStem in GoodMorningCore.
"""

import math
import os
import random
import struct
import wave

RATE = 22050
LOOP = 16.0
ALARM = 28.0
N = int(RATE * LOOP)
TAU = 2 * math.pi


def silence():
    return [0.0] * N


def add_note(buf, start, partials, length):
    """Adds a decaying tone that wraps around the end of the loop, keeping it seamless.
    partials: (frequency, amplitude, decay seconds)."""
    first = int(start * RATE)
    for i in range(int(length * RATE)):
        t = i / RATE
        attack = min(1.0, t / 0.008)
        value = 0.0
        for freq, amp, decay in partials:
            value += amp * math.exp(-t / decay) * math.sin(TAU * freq * t)
        buf[(first + i) % N] += value * attack


def dawn_chimes():
    buf = silence()
    scale = [523.25, 587.33, 659.25, 783.99, 880.0, 1046.5]
    order = [0, 2, 4, 3, 1, 4, 2, 5]
    for k, step in enumerate(order):
        f = scale[step]
        add_note(buf, k * 2.0 + (0.12 if k % 2 else 0.0),
                 [(f, 1.0, 1.6), (f * 2.76, 0.28, 0.7), (f * 5.4, 0.1, 0.3), (f * 0.5, 0.25, 2.2)], 7.0)
    return buf


def singing_bowl():
    buf = silence()
    for start, f in ((0.0, 196.0), (8.0, 220.0)):
        add_note(buf, start,
                 [(f, 1.0, 4.5), (f * 1.006, 0.8, 4.5), (f * 2.71, 0.35, 2.5), (f * 2.725, 0.25, 2.5),
                  (f * 5.15, 0.12, 1.2)], 15.0)
    return buf


def soft_harp():
    buf = silence()
    chords = [
        [261.63, 329.63, 392.0, 523.25],
        [220.0, 261.63, 329.63, 440.0],
        [174.61, 220.0, 261.63, 349.23],
        [196.0, 246.94, 293.66, 392.0],
    ]
    pattern = [0, 1, 2, 3, 2, 1, 2, 3]
    for bar, chord in enumerate(chords):
        for k, idx in enumerate(pattern):
            f = chord[idx]
            partials = [(f * h, 1.0 / (h * h) if h > 1 else 1.0, 1.8 / h) for h in range(1, 6)]
            add_note(buf, bar * 4.0 + k * 0.5, partials, 5.0)
    return buf


def ocean_waves():
    rng = random.Random(7)
    extra = int(RATE * 1.0)
    raw = []
    low = 0.0
    lower = 0.0
    for _ in range(N + extra):
        white = rng.uniform(-1, 1)
        low += 0.12 * (white - low)      # hiss of the surf
        lower += 0.015 * (white - lower)  # rumble underneath
        raw.append(low + 2.5 * lower)
    # Crossfade the tail into the head so the noise loops without a seam.
    buf = raw[:N]
    for i in range(extra):
        w = i / extra
        buf[i] = raw[N + i] * (1 - w) + raw[i] * w
    for i in range(N):
        phase = (i / RATE) % 8.0 / 8.0
        # A wave swells slowly, breaks, then drains away.
        swell = math.sin(math.pi * phase ** 0.7) ** 2
        buf[i] *= 0.12 + 0.88 * swell
    return buf


def morning_birds():
    buf = silence()
    # Quiet pad. Frequencies are whole numbers of cycles per loop, so it is seamless.
    pad = [round(f * LOOP) / LOOP for f in (130.81, 196.0, 329.63)]
    for i in range(N):
        t = i / RATE
        tremolo = 0.75 + 0.25 * math.sin(TAU * t / 8.0)
        buf[i] = 0.10 * tremolo * sum(math.sin(TAU * f * t) / (k + 1) for k, f in enumerate(pad))
    rng = random.Random(3)
    t = 0.4
    while t < LOOP - 0.2:
        base = rng.uniform(2400, 4200)
        for _ in range(rng.randint(2, 5)):
            length = rng.uniform(0.06, 0.14)
            rise = rng.uniform(-900, 1400)
            first = int(t * RATE)
            count = int(length * RATE)
            phase = 0.0
            for i in range(count):
                x = i / count
                phase += TAU * (base + rise * x) / RATE
                buf[(first + i) % N] += 0.35 * math.sin(math.pi * x) ** 2 * math.sin(phase)
            t += length + rng.uniform(0.03, 0.09)
        t += rng.uniform(0.5, 1.6)
    return buf


def normalize(buf, peak):
    top = max(abs(v) for v in buf) or 1.0
    return [v * peak / top for v in buf]


def write(path, samples):
    with wave.open(path, "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, v)) * 32767)) for v in samples))


def alarm_version(loop):
    """Starts almost silent and swells over 20 seconds."""
    out = []
    for i in range(int(RATE * ALARM)):
        t = i / RATE
        ramp = min(1.0, t / 20.0)
        out.append(loop[i % N] * (0.04 + 0.96 * ramp * ramp))
    return out


SOUNDS = {
    "dawn-chimes": dawn_chimes,
    "singing-bowl": singing_bowl,
    "ocean-waves": ocean_waves,
    "soft-harp": soft_harp,
    "morning-birds": morning_birds,
}

if __name__ == "__main__":
    folder = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "App", "GoodMorning", "Sounds")
    os.makedirs(folder, exist_ok=True)
    for name, make in SOUNDS.items():
        loop = normalize(make(), 0.85)
        write(os.path.join(folder, name + ".wav"), loop)
        write(os.path.join(folder, name + "-alarm.wav"), alarm_version(loop))
        print("wrote", name)
