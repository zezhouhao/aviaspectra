# Troubleshooting

[中文](TROUBLESHOOTING.md)


| Symptom | What to do |
|---|---|
| xcrun / swiftc missing | Run `xcode-select --install`, finish installation, then check again |
| Intel or Rosetta warning | v1 requires native Apple Silicon; do not force Intel dependencies |
| Slow/interrupted download | Rerun setup. Verified files are reused and partial downloads can resume. Transfers below 1 KB/s for 60 seconds abort and retry within limits; persistent failure exits explicitly. Check access to official GitHub Raw/PyPI |
| curl cannot resume | Remove only the reported `.dependencies/FILENAME.part`, then retry from the start; never remove user audio |
| SHA-256 mismatch | The script stops and removes the corrupt partial. Download again; do not bypass verification |
| SDK / availability build error | Keep the full error, check tools and validation records, and open an Issue; do not assume older-system compatibility |
| Finder still shows a music player | Close preview, open AviaSpectra once, check Quick Look settings and `manage.py status`, then enable again |
| Want the full recording after selection inference | Use **返回整体**; overview/double-click only resets zoom |
| Location filter returns nothing | Verify the recording location or compare with Global; the prior may exclude vagrants |
| No candidates | Does not prove no bird sound: noise, model coverage, short/narrow selection or thresholds may explain it |
| Model missing | Fetch dependencies and rebuild; do not rename models or rearrange app internals |
| Invalid signature | Rebuild the whole app locally; do not edit signed Contents or disable security |
| Species link fails | Check the website/network or taxonomy; search the scientific name manually. Inference does not depend on these sites |

## Older prototype and other extensions

The new extension is `local.aviaspectra.preview.quicklook`; the old BirdScope prototype is `local.birdscope.preview.prototype.quicklook`. The installer does not modify the old prototype. If you installed it and explicitly decide to switch:

```sh
pluginkit -e ignore -i local.birdscope.preview.prototype.quicklook
python3 scripts/manage.py enable
```

Only do this after the user chooses to switch. Other audio preview extensions may affect priority; select through System Settings rather than unregistering everything or killing Finder.

## Reporting an issue

Use the bilingual Issue template. Include chip, macOS, developer tools, failing stage and logs with private paths removed. Do not upload credentials or unauthorized recordings. Synthetic checks: `python3 tests/smoke.py`.
