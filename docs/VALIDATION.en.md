# Validation record

[中文](VALIDATION.md)


Initial checks: 2026-11-12; rename revalidation: 2026-11-13. Source checks, local execution and distribution validation are distinguished. A successful build does not prove installation on every Mac.

## Historical local checks — 1.0.0

Environment: Apple Silicon, macOS 27.0.1, Apple Command Line Tools, Python 3.9.6, Swift 6.4 in Swift 5 language mode.

| Check | Result |
|---|---|
| Separate source directory; no author-specific paths or virtual environment | Passed |
| arm64 app/extension, Mach-O minimum macOS 14.0 | Passed; not just an Info.plist edit |
| PNG resizing, ICNS creation and embedding | Passed |
| Local app, extension and runtime signatures | Passed |
| Synthetic 1 kHz WAV spectrogram | Peak 1007.8125 Hz, within FFT-bin resolution |
| Native inference on silence | Zero candidates; no crash |
| Equal-factor zoom, pointer anchors, boundaries and box coordinates | Passed |
| Whole → selection → clear → whole | Time window and candidates restored |
| Return-to-whole while selected inference is running | Cancellation and stale-callback isolation passed |
| Authorized real MP3 copy, excluded from distribution | 18 windows; top candidate Passerina ciris, confidence about 0.996, not accuracy |
| Interrupted/corrupt downloads and cache reuse | Simulated checks passed; corrupt downloads rejected and partial transfers retained where appropriate |
| Refuse unknown apps/symlinks; backup own app; uninstall to Trash | Temporary-directory simulation, no existing installation changed |
| No private paths, real audio, credentials or large model files in source | Export checks |

Live network validation downloaded the official LiteRT wheel and English/Chinese labels. Some larger model transfers stalled; the build used existing local caches whose SHA-256 matched the same official manifest. Low-speed timeouts and bounded retries were added. **A complete uncached download and first installation still require testing on a fresh machine with working connectivity.**

## Prototype evidence

The shared core controller's Finder MP3/WAV preview, autoplay and native inference were previously verified on the development Mac. Native/Python confidence differences were about 5e-7. Location filters and short selections also had tests. Prototype evidence does not validate the renamed release identifier on another Mac.

## Not yet verified

- Building/running on target macOS 14, 15, 26 and other systems.
- Clean-account installation → System Settings enablement → Finder preview.
- Complete Finder gesture/location/link acceptance on other macOS versions.
- The 1.0.1 GitHub Actions result must be checked separately from these local results.
- Intel, Windows and Linux are outside v1 support.

At the time of the initial 1.0.0 checks, the release extension was not installed/registered. See the 1.0.1 update below for the current development-Mac installation.

## Reproduce

```sh
bash scripts/setup.sh --build-only
python3 -m unittest discover -s tests -p 'test_*.py'
python3 tests/smoke.py
```

Native report: build/tests/smoke-report.json; synthetic audio is in the same directory. Generated files are not committed. Finder interaction requires manual acceptance checks in the installation guide.

## Rename checks — 2026-11-13

App/executable names, extension class and bundle identifiers were updated to AviaSpectra. Rebuild, signature checks, six management/download tests and native smoke checks passed. The installed old prototype was unchanged.

## How to read the speed claim

Earlier short-recording demonstrations displayed about 0.1–0.6 seconds of analysis time in the UI. These are a few observed readings, not a formal performance study. Cold/warm cache conditions were not controlled; the timer is not a standardized end-to-end measure from pressing Space. Initial model loading, cache state, hardware and recording length affect actual waiting. Do not claim every recording takes under a second or that an entire collection is processed in that time.

## 1.0.1 update — 2026-11-15

- Installed and enabled the formal 1.0.1 app and Quick Look extension on the development Mac; retained the previous app as a backup.
- Six management/download tests and the full native smoke suite passed. The suite checks real 850/1080 pt layouts with one/three candidates, button bounds, hit targets and XC/eBird action routing.
- Finder MP3 preview showed the new fixed result rows, **置信度** (confidence) labels and autoplay. The standalone WAV preview also showed the updated labels and autoplay.
- Standalone MP3/WAV playback, selection recognition, equal-axis zoom and return-to-whole were manually tested during local review. Clicking eBird opened the matching Carrion Crow page in Safari.
- Finder browser opening was refused during testing. The extension now requests opening through its host and provides a Copy link prompt on failure. **Successful browser launch from the final reloaded extension has not been verified; this remains a host-specific limitation, not a completed universal link fix.**
- The new documentation image is an actual installed-app screenshot of bundled XC24828.wav. Only window capture, resizing and JPEG conversion were used.
- The inference algorithm and confidence values are unchanged by the terminology update. UI confidence is the highest retained window value for each species, not calibrated accuracy.
