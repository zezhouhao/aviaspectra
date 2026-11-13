"""Exercise install boundaries in temporary folders, with system commands mocked."""
import importlib.util,plistlib,tempfile,unittest
from pathlib import Path
from unittest.mock import patch
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('manage',ROOT/'scripts/manage.py');manage=importlib.util.module_from_spec(spec);spec.loader.exec_module(manage)
class ManagementTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory();self.base=Path(self.tmp.name)
        self.root=self.base/'project';self.home=self.base/'home';self.home.mkdir()
        self.dest=self.home/'Applications/AviaSpectra.app'
        self.patches=[patch.object(manage,'ROOT',self.root),patch.object(manage,'APP',self.dest),patch.object(Path,'home',return_value=self.home),patch.object(manage,'run',side_effect=self.fake_run)]
        for p in self.patches:p.start()
        self.makeapp(self.root/'build/AviaSpectra.app',manage.ID)
    def tearDown(self):
        for p in reversed(self.patches):p.stop()
        self.tmp.cleanup()
    def makeapp(self,path,identifier):
        (path/'Contents').mkdir(parents=True);(path/'Contents/Info.plist').write_bytes(plistlib.dumps({'CFBundleIdentifier':identifier}))
    def fake_run(self,args):
        if args[0]=='ditto':
            import shutil
            shutil.copytree(args[1],args[2])
    def test_refuse_unrelated_app(self):
        self.makeapp(self.dest,'unrelated.app')
        with self.assertRaises(RuntimeError):manage.manage('install')
        self.assertEqual(manage.identity(self.dest),'unrelated.app')
    def test_install_backup_and_recoverable_uninstall(self):
        manage.manage('install');(self.dest/'old-version-marker').write_text('keep')
        manage.manage('install')
        saved=list((self.home/'Library/Application Support/AviaSpectra/Backups').glob('*.app'))
        self.assertEqual(len(saved),1);self.assertTrue((saved[0]/'old-version-marker').exists())
        audio=self.home/'recording.wav';audio.write_bytes(b'untouched')
        manage.manage('uninstall')
        self.assertFalse(self.dest.exists());self.assertEqual(audio.read_bytes(),b'untouched')
        self.assertEqual(len(list((self.home/'.Trash').glob('*.app'))),1)
    def test_refuse_symlink(self):
        self.dest.parent.mkdir(parents=True);self.dest.symlink_to(self.root/'build/AviaSpectra.app')
        with self.assertRaises(RuntimeError):manage.manage('install')
if __name__=='__main__':unittest.main()
