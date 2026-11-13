# AI-assisted installation protocol

[中文](AI_INSTALL.md)


For AI coding tools that can read this repository and run local terminal commands. Run all commands at the repository root. This document does not authorize actions beyond the user's request.

## Scope

Within the user's authorization, compile locally, install, and enable Quick Look. No Apple Developer Program, API key or audio upload is needed. Explain the model download, compilation and current-user extension registration. Do not modify original audio or unrelated download/analysis programs.

## Sequence

1. Read README.en.md, AGENTS.md, INSTALL.en.md and VALIDATION.en.md; check current limitations.
2. Run `python3 scripts/doctor.py`. If tools are missing, guide the user through `xcode-select --install`. Do not accept licenses or handle credentials on their behalf. Stop on Intel/Rosetta rather than guessing compatibility.
3. Read setup.sh, fetch_dependencies.py, build.py and manage.py. Run `bash scripts/setup.sh`; if only building is authorized, use `--build-only` without extension registration.
4. Download only official artifacts from `dependencies/manifest.json`. Retry interrupted transfers, but never bypass hashes/TLS or use an unverified mirror. Similar filenames do not make models interchangeable.
5. Run `python3 tests/smoke.py` and check signing, minimum OS version and native inference. Synthetic fixtures go in build/tests; user audio is untouched.
6. Check `python3 scripts/manage.py status`. Ask the user to open AviaSpectra once, then select audio in Finder and press Space. Follow troubleshooting if necessary. A successful pluginkit response does not prove the UI works.
7. With authorized audio, verify MP3/WAV preview, autoplay, two-axis zoom, links, recording location, box recognition and return-to-whole. Without real audio, generate synthetic WAV using `python3 tests/make_fixtures.py`; never describe it as a real bird recording.
8. Report the install path, verified/unverified checks, limits and disable/uninstall commands.

## Troubleshooting boundaries

- If a tool sandbox blocks native image/audio services, use its approval flow for the required build/test command. Do not change system security settings.
- No sudo, global security disabling, bulk xattr clearing, SIP changes or killing Finder.
- Do not overwrite unknown apps; the installer checks identity and backs up its own version.
- Do not automatically disable other preview extensions. Report conflicts and let the user choose.
- Do not install a background LaunchAgent, HTTP inference service or Python environment. Inference uses native LiteRT.
- Never commit private recordings, personal-path logs, tokens or credentials.
- Do not describe scores as accuracy, or promise geographic filtering always improves recognition.
- State when a new system or clean account has not been tested. The author's results are not proof of this user's installation.

## Handoff example

“Installed at …; verified …; still awaiting your confirmation of …. Disable with …; uninstall with …. This version handles only the first 120 seconds, and model candidates need listening verification.”
