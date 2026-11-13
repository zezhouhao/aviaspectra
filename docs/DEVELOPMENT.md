# 开发与复现

[English](DEVELOPMENT.en.md)


## 结构

- `Sources/AudioAnalysis.swift`：AVFoundation 读取、Accelerate FFT、声谱和波形。
- `PreviewController.swift`：应用和 Quick Look 共用界面、双轴缩放、选框、播放器、返回整体。
- `Recognition.swift` / `AudioSelection.swift`：48 kHz 转换、3秒分窗、选框带通与后台任务取消。
- `NativeBirdEngine.swift` / `LiteBridge.c`：LiteRT CPU C API、声学/地理模型、候选缓存。
- `SpeciesLinks.swift` / `LocationChooser.swift`：物种链接、浮动卡片与地点设置。
- `main.swift` / `QuickLook.swift`：独立应用与扩展入口。
- `scripts/`：环境检查、依赖获取、构建、当前用户应用管理。
- `dependencies/`：固定版本清单；下载内容不进 Git。
- `vendor/`：LiteRT C 头文件；不含编译库。

## 构建与测试

```sh
bash scripts/setup.sh --build-only
python3 -m unittest discover -s tests -p 'test_*.py'
python3 tests/smoke.py
```

编译明确使用 `arm64-apple-macosx14.0`；Info.plist 最低版本与 Mach-O 检查必须一致。最低编译目标不等于已在旧系统完成 GUI 验证。Python 仅标准库；从官方 wheel 提取 dylib 并校验，无需其 cp312 Python ABI。

下载量约81 MB，构建会把模型与运行库各打包到应用和扩展中，以满足 Quick Look 沙盒独立加载。CPU推断，不需要 GPU。所有可执行文件本机临时签名；build失败不替换上一次成功输出。

## UI 与语义

缩放不触发选框识别；选框坐标始终是原音频时间/频率。全览只重置显示，返回整体恢复全段候选。取消旧任务后，旧回调不能覆盖新结果。播放与原文件只读。

声谱 FFT2048/Hann，显示第1声道0–12kHz。识别最多8声道，每声道推断后按类取最大值；V2.4 logits sigmoid 后排序。每窗返回前5且评分≥0.1，界面候选≥0.5。地理模型以纬度、经度、全年(-1)为输入，先验≥0.03保留；不重新校准声学分数。缓存包含音频PCM内容与地点等参数；改变模型/算法时需升级缓存键。

## 自动检查

`.github/workflows/build.yml` 用 GitHub macOS arm64 runner 构建与运行测试，不注册预览扩展、不发布二进制。工作流已准备，首次上传后需实际查看 Actions 结果；不应展示未经运行的“CI通过”徽章。

官方 runner 说明：https://docs.github.com/en/actions/reference/runners/github-hosted-runners

## 图标

`assets/AviaSpectra.png` 为原始 AI 图标。构建用系统 sips 生成多尺寸 PNG，再用 iconutil 输出 ICNS。不需要 Pillow 或图像 API。创作提示词见 `assets/ICON_PROMPT.md`。

公开文档、图示与发布说明须同步维护中英文；应用界面目前为中文，不应混淆两者。
