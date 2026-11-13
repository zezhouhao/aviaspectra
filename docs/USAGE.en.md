# Usage

[中文](USAGE.md)


Select an MP3/WAV in Finder and press Space. The standalone app also opens files with Command+O. Autoplay is on by default; uncheck the control at the bottom to turn it off.

## Spectrogram and playback

The horizontal axis is original audio time in seconds; the vertical axis is frequency in kHz. Brighter colour indicates stronger spectral magnitude. A waveform sits above the spectrogram; a white line marks playback. Click the plot or drag the playback slider to seek. Space toggles playback in the standalone app; in Finder it normally closes Quick Look.

## Zoom and select

Scroll, two-finger vertical scroll, or pinch to zoom both axes equally around the pointer. Horizontal/Shift-scroll pans time. Option-scroll pans the time/frequency view. Double-click or use the zoom-factor overview button to reset the view. Zoom recomputes the spectrogram for the local time range but does not change the FFT's underlying frequency resolution.

Drag a rectangle on the spectrogram. Its yellow label shows original time and frequency. **识别选框** (Recognize selection) crops by time and applies a band-pass filter before inference; it does not simply analyse the visible viewport. A narrow band can remove harmonics. Audio shorter than three seconds is zero-padded.

**清除** (Clear) removes only the box. **返回整体** (Return to whole) clears it, resets the view, and restores whole-recording candidates. Playback position and location settings are retained; the file is not reopened.

## Candidates and links

The floating card displays up to three candidates; drag its background to avoid obscuring the plot. A menu exposes more candidates. Chinese names, scientific names, scores and timeline colours correspond. Click a scientific name for XC, or eBird for its species page. Taxonomy differences can break a link and do not establish an identification.

Time spans merge overlapping three-second windows for a species. They do not precisely locate event boundaries or frequency bands. Multiple candidates can reflect mixed bird sounds or misclassification.

## Location

Use **地点：全球** (Location: Global) to choose a city preset or enter the recording's coordinates. The prior is year-round; month filtering is not implemented. East/north are positive, west/south negative. Device location is not read. The app and preview extension have separate preferences, so you may need to set both. Check the location when reviewing files from another region.

## Data and privacy

Audio is neither modified nor uploaded. Initial setup downloads models; inference is offline. Cached candidates are associated with content hashes. Clicking a species link sends the species name or code to its website via your browser, never the audio. Each app/extension stores inference caches under `AviaSpectra/` in its system cache directory.
