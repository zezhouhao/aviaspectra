#!/usr/bin/env python3
"""Read-only prerequisite check. Does not install or change system settings."""
import platform, shutil, subprocess, sys
from pathlib import Path

def check():
    issues=[]
    if sys.version_info<(3,9):issues.append('Python 3.9 or newer is required (Apple Command Line Tools includes Python).')
    if platform.system()!='Darwin':issues.append('AviaSpectra requires macOS.')
    if platform.machine()!='arm64':issues.append('Version 1 supports Apple Silicon, running natively. Intel/Rosetta builds are not supported.')
    version=platform.mac_ver()[0]
    if version and int(version.split('.')[0])<14:issues.append('The build target is macOS 14 or later.')
    for tool in ['xcrun','codesign','curl','sips','iconutil','ditto','pluginkit']:
        if not shutil.which(tool):issues.append('Missing tool: '+tool)
    if shutil.which('xcrun'):
        for tool in ['swiftc','clang']:
            r=subprocess.run(['xcrun','--find',tool],capture_output=True,text=True)
            if r.returncode:issues.append('Install Apple Command Line Tools: xcode-select --install')
    if issues:
        raise RuntimeError('\n'.join(dict.fromkeys(issues)))
    print('OK: macOS '+version+', Apple Silicon, Python '+platform.python_version()+', build tools available.')
    print('Build target: macOS 14+. Verified locally only on macOS 27; see docs/VALIDATION.md.')
    print('Working folder: '+str(Path(__file__).resolve().parents[1]))

if __name__=='__main__':
    try:check()
    except RuntimeError as e:sys.exit(str(e))
