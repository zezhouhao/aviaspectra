# Development and reproduction

[中文](DEVELOPMENT.md)


## Structure

- `Sources/AudioAnalysis.swift`: AVFoundation decoding, Accelerate FFT, waveform and spectrogram.
- `PreviewController.swift`: shared app/Quick Look UI, two-axis zoom, selection, player, return-to-whole.
- `Recognition.swift` / `AudioSelection.swift`: 48 kHz conversion, three-second windows, selection filtering and cancellation.
- `NativeBirdEngine.swift` / `LiteBridge.c`: LiteRT CPU C API, acoustic/geographic models and cache.
- `SpeciesLinks.swift` / `LocationChooser.swift`: links, floating card and recording-location settings.
- `main.swift` / `QuickLook.swift`: app and extension entry points.
- `scripts/`: checks, dependency fetching, building, current-user app management.
- `dependencies/`: pinned manifests; downloaded artifacts stay out of Git.
- `vendor/`: LiteRT C headers, no compiled runtime.

## Build and test

```sh
bash scripts/setup.sh --build-only
python3 -m unittest discover -s tests -p 'test_*.py'
python3 tests/smoke.py
```

Compile explicitly for `arm64-apple-macosx14.0`; Info.plist and Mach-O minimum versions must agree. The deployment target is not proof of GUI testing on older systems. Python uses only the standard library; the verified official wheel supplies a native dylib, not a cp312 Python ABI dependency.

About 81 MB is downloaded. Models/runtime are embedded in both app and extension so the sandboxed Quick Look process loads them independently. Inference is CPU-based. Executables are locally ad-hoc signed; a failed build does not replace the last successful output.

## UI semantics

Zoom does not invoke selection recognition. Selection coordinates remain in original audio time/frequency. Overview resets only the view; return-to-whole restores all candidates. Cancelled tasks must not overwrite newer results through stale callbacks. Audio remains read-only.

Spectrogram: FFT 2048/Hann, channel 1, 0–12 kHz. Recognition: at most eight channels, per-class maximum after per-channel inference; sigmoid V2.4 logits before ranking. Each window returns its top five scores ≥0.1; UI candidates require ≥0.5. The geographic model takes latitude, longitude and year-round (-1), retaining priors ≥0.03 without recalibrating acoustic scores. Cache keys include PCM content and location parameters; bump keys when models/algorithms change.

## Automated checks

`.github/workflows/build.yml` builds/tests on a macOS arm64 runner. It does not register the preview extension or publish binaries. The first online run still requires verification; do not show a passing badge before an actual pass.

[Official runner reference](https://docs.github.com/en/actions/reference/runners/github-hosted-runners).

## Icon and documentation

`assets/AviaSpectra.png` is the AI-generated source icon. System sips generates sizes; iconutil creates ICNS. No Pillow/image API is needed at install time. See [icon provenance](../assets/ICON_PROMPT.md).

Keep Chinese and English pages, diagrams, links, release notes and Issue templates in sync; see [publishing policy](BILINGUAL.en.md).
