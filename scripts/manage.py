#!/usr/bin/env python3
"""Manage only this release's per-user app. No sudo, no Gatekeeper changes."""
import argparse,datetime,os,plistlib,shutil,subprocess,sys,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
APP=Path.home()/'Applications/AviaSpectra.app'
ID='local.aviaspectra.preview';EXT_ID=ID+'.quicklook'
LS='/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister'
def run(args):subprocess.run([str(a) for a in args],check=True)
def identity(path):
    try:return plistlib.loads((path/'Contents/Info.plist').read_bytes()).get('CFBundleIdentifier')
    except (OSError,plistlib.InvalidFileException):return None

def require_app():
    if APP.is_symlink() or identity(APP)!=ID:raise RuntimeError('Expected AviaSpectra app not found at '+str(APP))
def manage(action):
    if action=='install':
        source=ROOT/'build/AviaSpectra.app'
        if identity(source)!=ID:raise RuntimeError('Build first: bash scripts/setup.sh --build-only')
        run(['codesign','--verify','--deep','--strict',source])
        if APP.exists() or APP.is_symlink():
            require_app()
            # Keep a recoverable previous version instead of silently overwriting an unrelated app.
            backup=Path.home()/'Library/Application Support/AviaSpectra/Backups'
            backup.mkdir(parents=True,exist_ok=True)
            dest=backup/('AviaSpectra-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f')+'.app')
            print('Previous app saved to '+str(dest));shutil.move(str(APP),dest)
        APP.parent.mkdir(parents=True,exist_ok=True)
        run(['ditto',source,APP]);run([LS,'-f',APP])
        run(['pluginkit','-a',APP/'Contents/PlugIns/AviaSpectraQuickLook.appex'])
        run(['pluginkit','-e','use','-i',EXT_ID])
        print('Installed: '+str(APP))
        print('Open AviaSpectra once, then select an MP3/WAV in Finder and press Space.')
        print('If needed, enable AviaSpectra in System Settings: search for Quick Look / Extensions.')
        print('If an old BirdScope prototype is enabled, see docs/TROUBLESHOOTING.md. This installer does not alter it.')
    elif action in ['enable','disable']:
        require_app();run(['pluginkit','-e','use' if action=='enable' else 'ignore','-i',EXT_ID])
        print('Close the current preview, then press Space again.')
    elif action=='status':
        print('App: '+str(APP)+' ('+str(identity(APP))+')')
        run(['pluginkit','-m','-v','-i',EXT_ID])
    elif action=='uninstall':
        require_app()
        run(['pluginkit','-e','ignore','-i',EXT_ID])
        run(['pluginkit','-r',APP/'Contents/PlugIns/AviaSpectraQuickLook.appex'])
        trash=Path.home()/'.Trash';trash.mkdir(exist_ok=True)
        dest=trash/('AviaSpectra-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f')+'.app')
        shutil.move(str(APP),dest)
        print('Moved app to Trash. Audio, preferences and caches were retained. Close existing preview windows.')

if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('action',choices=['install','enable','disable','status','uninstall']);args=p.parse_args()
    try:manage(args.action)
    except (RuntimeError,OSError,subprocess.CalledProcessError) as e:sys.exit(str(e))
