import math, struct, wave

RATE = 44100

def tone(freq, dur, vol=0.5):
    n = int(RATE * dur)
    out = []
    for i in range(n):
        t = i / RATE
        # Amplop naik-turun supaya tidak berbunyi "klik" di ujung nada.
        env = min(1.0, t / 0.012) * min(1.0, (dur - t) / 0.06)
        wave_val = math.sin(2 * math.pi * freq * t)
        # Harmonik kecil supaya terdengar seperti bel, bukan sinus polos.
        wave_val += 0.25 * math.sin(2 * math.pi * freq * 2 * t)
        out.append(vol * env * wave_val)
    return out

def silence(dur):
    return [0.0] * int(RATE * dur)

# Dua nada naik: C6 lalu E6, seperti bel pengumuman singkat.
samples = tone(1046.50, 0.16) + silence(0.05) + tone(1318.51, 0.30, 0.45)
samples += silence(0.10)

with wave.open(r"android/app/src/main/res/raw/notif.wav", "wb") as f:
    f.setnchannels(1)
    f.setsampwidth(2)
    f.setframerate(RATE)
    f.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32767)) for s in samples))

print("ok")
