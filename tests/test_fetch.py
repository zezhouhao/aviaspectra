"""Download failure checks: retained partials, integrity rejection and recovery."""
import hashlib,importlib.util,json,subprocess,tempfile,unittest,zipfile
from pathlib import Path
from unittest.mock import patch
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('fetch',ROOT/'scripts/fetch_dependencies.py');fetch=importlib.util.module_from_spec(spec);spec.loader.exec_module(fetch)
class FetchTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory();self.root=Path(self.tmp.name);self.cache=self.root/'cache';self.cache.mkdir();(self.root/'dependencies').mkdir()
        self.good=b'verified model fixture';self.model=self.cache/'model.tflite';self.part=self.cache/'model.tflite.part'
        item={'file':'model.tflite','source':'https://example.invalid/model','bytes':len(self.good),'sha256':hashlib.sha256(self.good).hexdigest()}
        (self.root/'dependencies/manifest.json').write_text(json.dumps([item]))
        lib=b'native runtime fixture';member='ai_edge_litert/libLiteRt.dylib'
        with zipfile.ZipFile(self.cache/'litert.whl','w') as z:z.writestr(member,lib)
        (self.root/'dependencies/runtime.json').write_text(json.dumps({'member':member,'sha256':hashlib.sha256(lib).hexdigest()}))
        self.patches=[patch.object(fetch,'ROOT',self.root),patch.object(fetch,'CACHE',self.cache)]
        for p in self.patches:p.start()
    def tearDown(self):
        for p in reversed(self.patches):p.stop()
        self.tmp.cleanup()
    def test_interrupted_partial_is_preserved(self):
        self.part.write_bytes(b'partial')
        with patch.object(fetch.subprocess,'run',return_value=subprocess.CompletedProcess([],28)) as run:
            with self.assertRaisesRegex(RuntimeError,'interrupted'):fetch.fetch()
            self.assertIn('--speed-time',run.call_args.args[0]);self.assertIn('--continue-at',run.call_args.args[0])
        self.assertEqual(self.part.read_bytes(),b'partial');self.assertFalse(self.model.exists())
    def test_corrupt_download_is_not_accepted(self):
        def bad(args):self.part.write_bytes(b'corrupt');return subprocess.CompletedProcess(args,0)
        with patch.object(fetch.subprocess,'run',side_effect=bad):
            with self.assertRaisesRegex(RuntimeError,'Integrity'):fetch.fetch()
        self.assertFalse(self.model.exists());self.assertFalse(self.part.exists())
    def test_verified_download_and_cache_reuse(self):
        def good(args):self.part.write_bytes(self.good);return subprocess.CompletedProcess(args,0)
        with patch.object(fetch.subprocess,'run',side_effect=good):fetch.fetch()
        self.assertEqual(self.model.read_bytes(),self.good)
        with patch.object(fetch.subprocess,'run',side_effect=AssertionError('Should not download valid cache')):fetch.fetch()
        self.assertTrue((self.cache/'libLiteRt.dylib').exists())
if __name__=='__main__':unittest.main()
