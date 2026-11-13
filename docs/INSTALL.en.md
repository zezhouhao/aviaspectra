# Installation

[中文](INSTALL.md)


## Requirements

- Apple Silicon Mac (M series), native arm64 terminal; Intel/Rosetta is not supported in v1.
- macOS 14+ deployment target; actual tested systems and gaps are documented in [VALIDATION.en.md](VALIDATION.en.md).
- Apple Command Line Tools, Python 3.9+, access to GitHub Raw and PyPI.
- Prefer a normal folder on internal storage, with at least 2 GB free for dependencies, module caches and the app.

## 1. Download

Choose **Code → Download ZIP** on GitHub and extract. In Terminal, type `cd ` (including the space), drag the extracted folder into Terminal, and press Return. The directory should contain `README.md`, `Sources`, and `scripts`.

For assisted installation, give the folder to an AI tool and follow [AI_INSTALL.en.md](AI_INSTALL.en.md). No Apple developer account is required.

## 2. Check tools

```sh
xcode-select -p
```

If tools are missing, run `xcode-select --install` and finish the system installer before building. You may need to accept Apple's tools license yourself.

```sh
python3 scripts/doctor.py
```

This check does not change system settings. If Python is missing, check the Command Line Tools installation first; do not install an entire BirdNET Python environment.

## 3. Build and install

```sh
bash scripts/setup.sh
```

The script checks the environment, downloads and SHA-256-verifies dependencies, compiles the arm64 app and extension, signs them locally, installs to `~/Applications/AviaSpectra.app`, registers the extension, and requests enablement.

Rerun after a download failure. Verified complete files are reused, and partial transfers can resume. The first download is about 81 MB. Models are embedded in the app and extension; normal inference is offline.

Build without installation: `bash scripts/setup.sh --build-only`. Install later: `python3 scripts/manage.py install`.

An existing app with the same identifier is backed up to `~/Library/Application Support/AviaSpectra/Backups/`. A different app or symlink at the target is not overwritten. Close the old app and preview before updating.

## 4. Open and enable

Open AviaSpectra in your personal Applications folder. It does not choose audio automatically on its first launch; use **打开其它音频…** (Open another audio file).

Select an MP3/WAV in Finder and press Space. If you still see the system music player, search System Settings for Quick Look or Extensions and enable AviaSpectra. Names and locations vary by macOS version.

Check registration with `python3 scripts/manage.py status`; request enablement with `python3 scripts/manage.py enable`. Close and reopen the preview. A successful command is not proof of working Finder preview: verify the spectrogram and playback visually.

This is ad-hoc-signed local source compilation, not a notarized binary. If macOS blocks the app, check the source and build, and use the system's per-app handling options. Do not disable Gatekeeper globally or remove quarantine flags in bulk.

## 5. Verify

Use local MP3 and WAV files you are entitled to use. Confirm:

1. Space opens the spectrogram and starts playback.
2. Analysis shows candidates or an explicit no-reliable-candidates result.
3. Both axes zoom; drawing a box and pressing **识别选框** re-analyses it.
4. **返回整体** removes the selection and restores the whole view and candidates.
5. Location settings and species links work; verify species manually.
6. Original files are unchanged.

## Disable or uninstall

- Disable: `python3 scripts/manage.py disable`
- Enable: `python3 scripts/manage.py enable`
- Uninstall: close app/previews, then `python3 scripts/manage.py uninstall`

Uninstall moves only this app to Trash. Audio, source, downloaded-model caches, preferences, and inference caches remain. No sudo or background-service shutdown is needed.
