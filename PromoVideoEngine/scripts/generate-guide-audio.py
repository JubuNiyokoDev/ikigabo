from __future__ import annotations

import asyncio
import json
import math
import os
import random
import struct
import subprocess
import wave
from pathlib import Path

import edge_tts


ROOT = Path(__file__).resolve().parent.parent
GUIDE_PATH = ROOT / "src" / "data" / "tutorial-guide.json"
INTERACTIONS_PATH = ROOT / "src" / "data" / "tutorial-interactions.json"
OUT_ROOT = ROOT / "public" / "audio" / "generated" / "guide"
VOICE_ROOT = OUT_ROOT / "voice"
SFX_ROOT = OUT_ROOT / "sfx"
MUSIC_ROOT = OUT_ROOT / "music"
TEMP_ROOT = ROOT / ".audio-temp"
VOICE_NAME = os.environ.get("IKIGABO_TTS_VOICE", "fr-FR-DeniseNeural")
VOICE_RATE = os.environ.get("IKIGABO_TTS_RATE", "-8%")


def ensure_dirs() -> None:
    for directory in [VOICE_ROOT, SFX_ROOT, MUSIC_ROOT, TEMP_ROOT]:
      directory.mkdir(parents=True, exist_ok=True)


def load_json(path: Path):
    with path.open("r", encoding="utf-8") as file:
        return json.load(file)


def write_wave(path: Path, samples: list[tuple[float, float]], sample_rate: int = 24000) -> None:
    with wave.open(str(path), "w") as file:
        file.setnchannels(2)
        file.setsampwidth(2)
        file.setframerate(sample_rate)
        for left, right in samples:
            file.writeframesraw(
                struct.pack(
                    "<hh",
                    int(max(-1.0, min(1.0, left)) * 32767),
                    int(max(-1.0, min(1.0, right)) * 32767),
                )
            )


def run_ffmpeg(input_path: Path, output_path: Path) -> None:
    subprocess.run(
        [
            "ffmpeg",
            "-y",
            "-i",
            str(input_path),
            "-codec:a",
            "libmp3lame",
            "-q:a",
            "4",
            str(output_path),
        ],
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def generate_click(path: Path, sample_rate: int = 24000) -> None:
    duration = 0.14
    total = int(duration * sample_rate)
    samples: list[tuple[float, float]] = []
    for index in range(total):
        t = index / sample_rate
        envelope = math.exp(-32 * t)
        wave_a = math.sin(2 * math.pi * 1800 * t)
        wave_b = math.sin(2 * math.pi * 950 * t)
        value = (wave_a * 0.75 + wave_b * 0.25) * envelope * 0.38
        samples.append((value, value))
    write_wave(path, samples, sample_rate)


def generate_ping(path: Path, sample_rate: int = 24000) -> None:
    duration = 0.8
    total = int(duration * sample_rate)
    samples: list[tuple[float, float]] = []
    for index in range(total):
        t = index / sample_rate
        envelope = math.exp(-4.5 * t)
        freq = 1320 - 280 * t
        value = math.sin(2 * math.pi * freq * t) * envelope * 0.34
        sparkle = math.sin(2 * math.pi * (freq * 1.8) * t) * envelope * 0.08
        samples.append((value + sparkle, value + sparkle))
    write_wave(path, samples, sample_rate)


def generate_whoosh(path: Path, sample_rate: int = 24000) -> None:
    duration = 0.9
    total = int(duration * sample_rate)
    rng = random.Random(42)
    samples: list[tuple[float, float]] = []
    for index in range(total):
        t = index / sample_rate
        progress = t / duration
        envelope = math.sin(math.pi * progress) ** 1.2
        noise = (rng.random() * 2 - 1) * envelope
        sweep = math.sin(2 * math.pi * (160 + 620 * progress) * t) * 0.15
        left = noise * 0.16 + sweep
        right = noise * 0.11 + sweep * 0.85
        samples.append((left, right))
    write_wave(path, samples, sample_rate)


def generate_music_bed(wav_path: Path, duration: int = 60, sample_rate: int = 24000) -> None:
    total = duration * sample_rate
    rng = random.Random(7)
    samples: list[tuple[float, float]] = []
    for index in range(total):
        t = index / sample_rate
        pad = (
            math.sin(2 * math.pi * 220 * t)
            + 0.7 * math.sin(2 * math.pi * 277.18 * t)
            + 0.55 * math.sin(2 * math.pi * 329.63 * t)
        ) / 3.0
        pad *= 0.11 * (0.72 + 0.28 * math.sin(2 * math.pi * 0.08 * t))

        pulse_gate = max(0.0, math.sin(2 * math.pi * 0.5 * t))
        pulse = math.sin(2 * math.pi * 440 * t) * pulse_gate * 0.018

        texture = (rng.random() * 2 - 1) * 0.012
        shimmer = math.sin(2 * math.pi * 660 * t) * 0.008 * (0.5 + 0.5 * math.sin(2 * math.pi * 0.12 * t))

        left = pad + pulse + texture + shimmer
        right = pad * 0.96 + pulse * 0.8 - texture + shimmer * 0.8
        samples.append((left, right))

    write_wave(wav_path, samples, sample_rate)


async def generate_voice_track(text: str, output_path: Path) -> None:
    communicate = edge_tts.Communicate(text=text, voice=VOICE_NAME, rate=VOICE_RATE)
    await communicate.save(str(output_path))


async def generate_voice_tracks(guide_data) -> None:
    tasks = []
    for episode in guide_data["episodes"]:
        output_path = VOICE_ROOT / f"{episode['id']}.mp3"
        tasks.append(generate_voice_track(episode["voiceover"], output_path))
    await asyncio.gather(*tasks)


def write_manifest(guide_data, interactions) -> None:
    manifest = {
        "video_duration": guide_data["video_duration_seconds"],
        "audio_tracks": {
            "music": "audio/generated/guide/music/season-1-bed.mp3",
            "voice_over": [
                {
                    "start": episode["time_start"],
                    "end": episode["time_end"],
                    "text": episode["voiceover"],
                    "asset": f"audio/generated/guide/voice/{episode['id']}.mp3",
                }
                for episode in guide_data["episodes"]
            ],
            "sfx": [
                {
                    "time": episode["time_start"] + step["at"],
                    "type": step["sfx"],
                    "asset": f"audio/generated/guide/sfx/{'whoosh-soft' if step['sfx'] == 'whoosh_soft' else step['sfx']}.wav",
                }
                for episode in guide_data["episodes"]
                for step in interactions.get(episode["id"], [])
            ],
        },
    }

    with (OUT_ROOT / "manifest.json").open("w", encoding="utf-8") as file:
        json.dump(manifest, file, ensure_ascii=False, indent=2)


def main() -> None:
    ensure_dirs()
    guide_data = load_json(GUIDE_PATH)
    interactions = load_json(INTERACTIONS_PATH)

    click_path = SFX_ROOT / "click.wav"
    ping_path = SFX_ROOT / "ping.wav"
    whoosh_path = SFX_ROOT / "whoosh-soft.wav"
    music_wav = TEMP_ROOT / "season-1-bed.wav"
    music_mp3 = MUSIC_ROOT / "season-1-bed.mp3"

    generate_click(click_path)
    generate_ping(ping_path)
    generate_whoosh(whoosh_path)
    generate_music_bed(music_wav, duration=60)
    run_ffmpeg(music_wav, music_mp3)

    asyncio.run(generate_voice_tracks(guide_data))
    write_manifest(guide_data, interactions)

    print("Guide audio generated successfully.")


if __name__ == "__main__":
    main()
