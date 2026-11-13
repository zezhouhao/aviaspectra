#!/usr/bin/env python3
"""Generate test signals, not bird recordings. Standard library only."""
import math,struct,wave
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'build/tests'
def generate():
    OUT.mkdir(parents=True,exist_ok=True)
    rate=48000;seconds=8
    def write(name,sample):
        with wave.open(str(OUT/name),'wb') as f:
            f.setnchannels(1);f.setsampwidth(2);f.setframerate(rate)
            f.writeframes(b''.join(struct.pack('<h',int(max(-1,min(1,sample(i/rate)))*32767)) for i in range(rate*seconds)))
    write('tone.wav',lambda t:0.2*math.sin(2*math.pi*1000*t))
    write('silence.wav',lambda t:0)
    write('chirps.wav',lambda t:0.3*math.sin(2*math.pi*(2000*t+450*(t%1)**2))*math.sin(math.pi*(t%1)/0.4)**2 if t%1<0.4 else 0)
    print('Synthetic fixtures: '+str(OUT))
if __name__=='__main__':generate()
