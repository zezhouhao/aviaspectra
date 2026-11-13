#!/usr/bin/env python3
"""Fetch immutable, hashed upstream artifacts; no pip packages are installed."""
import hashlib, json, subprocess, sys, zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
CACHE=ROOT/'.dependencies'

def digest(p):
    h=hashlib.sha256()
    with p.open('rb') as f:
        for block in iter(lambda:f.read(1024*1024),b''):h.update(block)
    return h.hexdigest()

def fetch():
    CACHE.mkdir(exist_ok=True)
    for item in json.loads((ROOT/'dependencies/manifest.json').read_text()):
        path=CACHE/item['file']
        if path.exists() and digest(path)==item['sha256']:
            print('Verified cache: '+path.name,flush=True);continue
        part=path.with_suffix(path.suffix+'.part')
        print('Downloading '+item['file'],flush=True)
        # curl retains partial progress and retries transient network errors. TLS stays enabled.
        r=subprocess.run(['curl','--fail','--location','--retry','3','--retry-delay','2','--retry-max-time','180','--speed-limit','1024','--speed-time','60','--connect-timeout','30','--max-time','900','--continue-at','-','--output',str(part),item['source']])
        if r.returncode:raise RuntimeError('Download interrupted. Run again to resume: '+item['file'])
        if part.stat().st_size!=item['bytes'] or digest(part)!=item['sha256']:
            part.unlink()
            raise RuntimeError('Integrity check failed; corrupt partial file removed: '+item['file'])
        part.replace(path)
    runtime=json.loads((ROOT/'dependencies/runtime.json').read_text())
    with zipfile.ZipFile(CACHE/'litert.whl') as z:data=z.read(runtime['member'])
    if hashlib.sha256(data).hexdigest()!=runtime['sha256']:raise RuntimeError('LiteRT binary hash mismatch')
    target=CACHE/'libLiteRt.dylib';target.write_bytes(data)
    print('Dependencies ready. Only the native dylib is extracted; Python 3.12 is NOT required.')

if __name__=='__main__':
    try:fetch()
    except (RuntimeError,OSError,zipfile.BadZipFile) as e:sys.exit(str(e))
