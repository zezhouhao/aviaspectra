# Changelog

[中文](CHANGELOG.md)


## 1.0.1 — 2026-11-15

- Replace the plot overlay with fixed, larger species rows above the spectrogram.
- Enlarge eBird buttons; route Quick Look links through the extension host and offer Copy link when refused.
- Use “置信度” (confidence) consistently; distinguish model confidence from accuracy.
- Add 850/1080 pt, single/multiple candidate, button-bounds and action-routing checks.
- Update real screenshots and bilingual docs; keep the included bird recordings.

## 1.0.0 — 2026-11-13

First source-sharing version, publicly named AviaSpectra (谱羽). Public release preparation and fresh-machine installation validation are separate; this record does not claim a completed GitHub release or passing online CI.

- Finder MP3/WAV spectrogram preview and autoplay.
- Native LiteRT/BirdNET V2.4 inference and recording-location filtering.
- Equal-factor two-axis zoom, panning and independent time-frequency box re-analysis.
- Return-to-whole restores complete view and whole-recording candidates.
- One floating candidate card and XC/eBird links.
- AI-generated icon and local build/install/disable/uninstall scripts.
- Pinned, hash-verified dependencies; bilingual documentation and AI setup instructions.
- Illustrated workflow and selection guides; clearer explanation of the large-collection inspection problem.
- Explicit arm64/macOS 14 deployment target; older systems still need device testing.
- No dependency on the author's paths, private audio or Python virtual environment.

Limits: first 120 seconds; Chinese app UI; no Intel support or notarized binary installer; candidates require manual verification.
