# 第三方材料与署名

[English](THIRD_PARTY_NOTICES.en.md)


AviaSpectra 是独立项目，并非 BirdNET、Cornell、eBird、xeno-canto、Apple 或 Google 的官方产品。

| 材料 | 上游 | 许可与处理 |
|---|---|---|
| BirdNET V2.4 声学与地理模型 | [BirdNET-Analyzer](https://github.com/birdnet-team/BirdNET-Analyzer) | CC BY-NC-SA 4.0；安装时下载，不转为 MIT |
| 英/中文标签与 eBird 映射 | 同上；精确来源在 dependencies/manifest.json | 保留模型关联数据署名，遵守上游条款，不声称是原创 |
| LiteRT 2.3.0 C 头文件 | [LiteRT v2.3.0](https://github.com/google-ai-edge/LiteRT/tree/v2.3.0/litert/c) | Apache 2.0；保留版权头 |
| LiteRT 原生库 | [ai-edge-litert 2.3.0](https://pypi.org/project/ai-edge-litert/2.3.0/) | Apache 2.0；从经校验的官方 wheel 提取，不要求 Python 运行环境 |
| 应用图标与操作示意图 | 项目图标使用 AI 绘图；操作图为原创矢量图 | 在适用范围内按项目许可提供，不声称独占商标权 |

BirdNET 署名：BirdNET Team、Cornell Lab of Ornithology 的 K. Lisa Yang Center for Conservation Bioacoustics，以及 Chemnitz University of Technology。参见 [BirdNET 许可](https://github.com/birdnet-team/BirdNET-Analyzer#license) 与 [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/)。保留署名和许可；模型使用仅限非商业，改编模型材料须遵守相同方式共享条件。源码许可与模型许可分别适用。

下载清单固定 SHA-256 与字节数；模型清单和声明同时打包到应用与预览扩展。模型未修改。中文标签和分类映射来自上游2.4.0快照，分类沿用 BirdNET V2.4，可能与网站现行分类不同。

vendor/litert/build_common/build_config.h 是最小本地 C 调用适配头，见 [vendor 说明](vendor/README.md)。仓库和应用不分发 XC 真实录音，测试音频为合成信号。

XC/eBird 链接通过用户浏览器打开；网站内容不打包、不再分发，离线推断不依赖这些网站。

MIT 和第三方许可原文保持不变；中文介绍用于理解，不替代原始许可文本。
