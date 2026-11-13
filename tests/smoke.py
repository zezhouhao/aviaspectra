#!/usr/bin/env python3
"""Native checks. Does not install/register the preview extension."""
import json,subprocess,sys
from pathlib import Path
from make_fixtures import generate,OUT,ROOT
APP=ROOT/'build/AviaSpectra.app';BINARY=APP/'Contents/MacOS/AviaSpectra'
def run(args):
    result=subprocess.run([str(a) for a in args],check=True,text=True,capture_output=True,timeout=120)
    return result.stdout

def main():
    if not BINARY.exists():sys.exit('Build first: bash scripts/setup.sh --build-only')
    generate()
    run(['codesign','--verify','--deep','--strict',APP])
    for binary in [BINARY,APP/'Contents/PlugIns/AviaSpectraQuickLook.appex/Contents/MacOS/AviaSpectraQuickLook']:
        assert 'arm64' in run(['file',binary])
        assert 'minos 14.0' in run(['xcrun','vtool','-show-build',binary])
    raw=run([BINARY,'--analyse',OUT/'tone.wav',OUT/'tone.png']);analysis=json.loads(raw)
    assert abs(analysis['peak_hz']-1000)<30,analysis
    assert abs(analysis['duration']-8)<0.01
    run([BINARY,'--recognize',OUT/'silence.wav',OUT/'silence.json'])
    result=json.loads((OUT/'silence.json').read_text())
    assert result['error'] is None and result['segments']
    assert all(not s['predictions'] for s in result['segments'])
    zoom=run([BINARY,'--check-zoom',OUT/'chirps.wav']).strip()
    restore=run([BINARY,'--check-restore',OUT/'silence.wav']).strip()
    assert zoom.endswith('PASS') and restore.endswith('PASS')
    report={'status':'PASS','spectrogram_1khz_peak_hz':analysis['peak_hz'],'silence_predictions':0,'zoom':zoom,'restore':restore,'quick_look_gui':'Manual verification required; no extension registration in this test.'}
    (OUT/'smoke-report.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps(report,ensure_ascii=False,indent=2))
if __name__=='__main__':main()
