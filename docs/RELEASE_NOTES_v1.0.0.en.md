# AviaSpectra 1.0.0 — source-first release

[中文](RELEASE_NOTES_v1.0.0.md)


Large recording collections should not require repeated switching between a player, spectrogram tool, recognizer and reference websites. Press Space in Finder to bring playback, a spectrogram and local BirdNET species candidates into one preview.

Some short-file demonstrations on the development Mac displayed 0.1–0.6 seconds of analysis time. This is not a formal or end-to-end benchmark; hardware, initial loading, cache state and file length affect actual waiting time.

Download the source ZIP, extract it, and ask a local AI assistant to follow [AI setup](AI_INSTALL.en.md), or run `bash scripts/setup.sh`. No Apple Developer Program membership is required.

Features: MP3/WAV Quick Look and autoplay; equal-factor zoom; time-frequency box re-analysis; return-to-whole; recording-location filtering; XC/eBird links.

Apple Silicon; macOS 14+ build target, actually tested on macOS 27.0.1. Other systems and fresh-machine Quick Look installation need further verification. GitHub documentation is Chinese/English; the app UI is Chinese.

This is locally compiled source, not a notarized ready-to-run installer. Only the first 120 seconds are handled. Candidates need manual verification. BirdNET models are noncommercial; see [README](../README.en.md) and [third-party notices](../THIRD_PARTY_NOTICES.en.md).
