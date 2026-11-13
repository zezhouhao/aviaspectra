AviaSpectra 1.0.0：在 Finder 按空格，查看鸟鸣声谱、播放音频并获得本地 BirdNET 物种候选。

[English](RELEASE_NOTES_v1.0.0.en.md)


本版本以源码分享：下载 Source code ZIP，解压后让 Codex 等本地 AI 工具按照 docs/AI_INSTALL.md 安装，或手动运行 `bash scripts/setup.sh`。无需 Apple Developer Program。

功能：MP3/WAV 快速预览与自动播放、等比例缩放、时间频率选框识别、返回整体、录音地点筛选、XC/eBird 物种链接。

兼容范围：Apple Silicon；构建目标 macOS 14+，目前实际验证为 macOS 27.0.1。其他目标版本和不同电脑的 Quick Look 安装需要进一步反馈验证。界面为中文。

注意：这是源码本机构建版，不是 Apple 公证的即装即用安装包。首版仅预览前120秒。模型结果为候选，需要复听；BirdNET 模型仅限非商业用途。完整许可与限制见 README 和 THIRD_PARTY_NOTICES.md。

面对海量鸟鸣文件，本工具把播放器、声谱、识别和参考资料入口集中到一次空格预览中。开发机短音频演示曾显示约0.1–0.6秒分析耗时；这不是统一端到端基准，首次加载、缓存、音频长度与设备会影响速度。GitHub文档提供中英文，应用界面仍为中文。
