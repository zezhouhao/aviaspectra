# Third-party materials

[中文](THIRD_PARTY_NOTICES.md)


AviaSpectra is an independent project. It is not an official product of BirdNET, Cornell, eBird, xeno-canto, Apple or Google.

| Material | Upstream | License / handling |
|---|---|---|
| BirdNET V2.4 acoustic and geographic models | [BirdNET-Analyzer](https://github.com/birdnet-team/BirdNET-Analyzer) | CC BY-NC-SA 4.0; downloaded at setup, never relicensed under MIT |
| BirdNET English/Chinese labels and eBird mapping | Same upstream, exact URLs in `dependencies/manifest.json` | Retained as model-associated data with BirdNET attribution; respect upstream terms, not claimed as original work |
| LiteRT 2.3.0 C headers | [google-ai-edge/LiteRT v2.3.0](https://github.com/google-ai-edge/LiteRT/tree/v2.3.0/litert/c) | Apache 2.0; copyright headers preserved |
| LiteRT native library | [ai-edge-litert 2.3.0 on PyPI](https://pypi.org/project/ai-edge-litert/2.3.0/) | Apache 2.0; native library extracted from the verified official wheel, not a Python runtime dependency |
| App icon and explanatory diagrams | AI-generated project icon; original vector diagrams | Original project asset, included under the project license to the extent applicable; no claim of exclusive trademark rights |

BirdNET credits: BirdNET Team, K. Lisa Yang Center for Conservation Bioacoustics / Cornell Lab of Ornithology, and Chemnitz University of Technology. Read [BirdNET's licensing information](https://github.com/birdnet-team/BirdNET-Analyzer#license) and [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/). Preserve attribution and license notices; model use is noncommercial, and adapted model materials must follow the share-alike terms. Source-code licensing is separate from model licensing.

Downloaded artifacts have pinned SHA-256 and byte counts. Model manifests and notices are copied into both the app and its preview extension. Models are unmodified. Chinese labels and taxonomy mappings use upstream 2.4.0 snapshots; classification follows BirdNET V2.4 and may differ from current website taxonomy.

`vendor/litert/build_common/build_config.h` is a minimal local C-consumer shim; see [vendor documentation](vendor/README.md). No XC recordings are distributed with this repository or app. Test audio is generated synthetically.

The app opens XC/eBird species links in the user's browser. Those websites' content is not bundled or redistributed. Neither website is required for offline inference.

## 真实体验音频 / Real demo recordings

Three MP3 recordings and one derived WAV in `samples/` are CC BY-SA 4.0, not MIT. Recordists: Sander Pieterse and Marie-Lan Taÿ Pamart. Full source links, attribution and changes: [中文](samples/README.md) · [English](samples/README.en.md).

`samples/` 中三段 MP3 和一份转换 WAV 采用 CC BY-SA 4.0，独立于 MIT 代码许可；录音者为 Sander Pieterse 和 Marie-Lan Taÿ Pamart。署名、来源、修改说明见上述双语页面。
