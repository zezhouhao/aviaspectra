#!/usr/bin/env python3
"""Build an ad-hoc signed arm64 app and Quick Look extension for local use."""
import hashlib,json,os,plistlib,shutil,subprocess,sys,tempfile
from pathlib import Path
from doctor import check
from fetch_dependencies import digest
ROOT=Path(__file__).resolve().parents[1]
BUILD=ROOT/'build'
ID='local.aviaspectra.preview'
EXT_ID=ID+'.quicklook'

def run(args):subprocess.run([str(a) for a in args],cwd=ROOT,check=True)
def make_icon(resources):
    iconset=BUILD/'AviaSpectra.iconset';iconset.mkdir(exist_ok=True)
    for points in [16,32,128,256,512]:
        for scale in [1,2]:
            name='icon_%dx%d%s.png'%(points,points,'@2x' if scale==2 else '')
            subprocess.run(['sips','-z',str(points*scale),str(points*scale),str(ROOT/'assets/AviaSpectra.png'),'--out',str(iconset/name)],check=True,stdout=subprocess.DEVNULL)
    run(['iconutil','-c','icns',iconset,'-o',resources/'AviaSpectra.icns'])

def build():
    check()
    cache=ROOT/'.dependencies'
    for item in json.loads((ROOT/'dependencies/manifest.json').read_text()):
        p=cache/item['file']
        if not p.exists() or digest(p)!=item['sha256']:raise RuntimeError('Run bash scripts/setup.sh --build-only to fetch verified dependencies first.')
    runtime=json.loads((ROOT/'dependencies/runtime.json').read_text())
    if not (cache/'libLiteRt.dylib').exists() or digest(cache/'libLiteRt.dylib')!=runtime['sha256']:raise RuntimeError('Runtime missing or changed. Run fetch_dependencies.py again.')
    BUILD.mkdir(exist_ok=True)
    # Build in a fresh staging folder so a failed build never replaces the previous output.
    stage=Path(tempfile.mkdtemp(prefix='stage-',dir=BUILD))
    try:
        app=stage/'AviaSpectra.app';contents=app/'Contents';res=contents/'Resources';mac=contents/'MacOS'
        res.mkdir(parents=True);mac.mkdir()
        version=(ROOT/'VERSION').read_text().strip()
        info={'CFBundleIdentifier':ID,'CFBundleName':'AviaSpectra','CFBundleDisplayName':'AviaSpectra','CFBundleExecutable':'AviaSpectra','CFBundlePackageType':'APPL','CFBundleVersion':'1','CFBundleShortVersionString':version,'LSMinimumSystemVersion':'14.0','NSHighResolutionCapable':True,'CFBundleIconFile':'AviaSpectra','CFBundleDocumentTypes':[{'CFBundleTypeName':'Audio','CFBundleTypeRole':'Viewer','LSHandlerRank':'Alternate','LSItemContentTypes':['public.mp3','com.microsoft.waveform-audio']}]}
        (contents/'Info.plist').write_bytes(plistlib.dumps(info))
        ext=contents/'PlugIns/AviaSpectraQuickLook.appex/Contents';(ext/'MacOS').mkdir(parents=True);(ext/'Resources').mkdir()
        extinfo={'CFBundleIdentifier':EXT_ID,'CFBundleName':'AviaSpectra Quick Look','CFBundleExecutable':'AviaSpectraQuickLook','CFBundlePackageType':'XPC!','CFBundleVersion':'1','CFBundleShortVersionString':version,'LSMinimumSystemVersion':'14.0','NSExtension':{'NSExtensionPointIdentifier':'com.apple.quicklook.preview','NSExtensionPrincipalClass':'AviaSpectraQuickLookController','NSExtensionAttributes':{'QLSupportedContentTypes':['public.mp3','com.microsoft.waveform-audio'],'QLSupportsSearchableItems':False}}}
        (ext/'Info.plist').write_bytes(plistlib.dumps(extinfo))
        for base in [contents,ext]:
            resources=base/'Resources'
            for name in ['model.tflite','geo.tflite','labels.txt','labels_zh.txt','ebird_codes.json']:shutil.copy2(cache/name,resources/name)
            shutil.copytree(ROOT/'Notices',resources/'Notices')
            shutil.copy2(ROOT/'dependencies/manifest.json',resources/'dependency-manifest.json')
            shutil.copy2(ROOT/'LICENSE',resources/'LICENSE')
            frameworks=base/'Frameworks';frameworks.mkdir()
            shutil.copy2(cache/'libLiteRt.dylib',frameworks/'libLiteRt.dylib')
            run(['codesign','--force','--sign','-',frameworks/'libLiteRt.dylib'])
        make_icon(res)
        obj=stage/'LiteBridge.o';target='arm64-apple-macosx14.0'
        run(['xcrun','clang','-target',target,'-O2','-I',ROOT/'vendor','-c',ROOT/'Sources/LiteBridge.c','-o',obj])
        names=['AudioAnalysis','PreviewController','Recognition','SpeciesLinks','NativeBirdEngine','AudioSelection','LocationChooser']
        common=['xcrun','swiftc','-target',target,'-swift-version','5','-O','-module-cache-path',BUILD/'ModuleCache']+[ROOT/'Sources'/(n+'.swift') for n in names]+['-import-objc-header',ROOT/'Sources/LiteBridge.h',obj,'-L',contents/'Frameworks','-lLiteRt','-Xlinker','-rpath','-Xlinker','@executable_path/../Frameworks']
        run(common+[ROOT/'Sources/main.swift','-o',mac/'AviaSpectra'])
        run(common+['-parse-as-library',ROOT/'Sources/QuickLook.swift','-o',ext/'MacOS/AviaSpectraQuickLook'])
        run(['codesign','--force','--sign','-','--entitlements',ROOT/'extension.entitlements',ext.parent])
        run(['codesign','--force','--sign','-',app])
        run(['codesign','--verify','--deep','--strict',app])
        for binary in [mac/'AviaSpectra',ext/'MacOS/AviaSpectraQuickLook']:
            details=subprocess.check_output(['xcrun','vtool','-show-build',str(binary)],text=True)
            if 'minos 14.0' not in details:raise RuntimeError('Unexpected deployment target: '+details)
        output=BUILD/'AviaSpectra.app'
        if output.exists():shutil.rmtree(output)
        shutil.move(str(app),output)
        print('Built: '+str(output))
    finally:shutil.rmtree(stage)

if __name__=='__main__':
    try:build()
    except (RuntimeError,OSError,subprocess.CalledProcessError) as e:sys.exit(str(e))
