# 安装指南

[English](INSTALL.en.md)


## 适用环境

- Apple Silicon Mac（M 系列），原生 arm64 终端；首版不支持 Intel/Rosetta。
- 编译目标 macOS 14+；实际测试环境与未验证项目见 [VALIDATION.md](VALIDATION.md)。
- Apple Command Line Tools，Python 3.9+，可访问 GitHub Raw 和 PyPI 的网络。
- 建议将项目放在内置存储的普通目录，给依赖、模块缓存和应用留出至少 2 GB 空间。

## 1. 下载项目

GitHub 项目首页点击 **Code → Download ZIP**，解压。打开终端，输入 `cd `（有一个空格），把解压后的项目文件夹拖入终端，再按回车。检查该目录中有 `README.md`、`Sources` 和 `scripts`。

如果交给 AI 操作，把项目文件夹交给它并阅读 [AI_INSTALL.md](AI_INSTALL.md)。无需先注册 Apple 开发者账号。

## 2. 检查工具

```sh
xcode-select -p
```

如果提示没有开发工具，运行 `xcode-select --install`，完成系统安装窗口后继续。不要在安装尚未结束时反复运行构建。此步骤可能需要你接受 Apple 工具许可。

```sh
python3 scripts/doctor.py
```

检查不修改系统设置。缺少 Python 时先检查 Command Line Tools 是否安装完整，不要为此把整个 BirdNET Python 环境装到电脑上。

## 3. 构建和安装

```sh
bash scripts/setup.sh
```

流程：环境检查 → 下载与 SHA-256 校验 → 编译 arm64 程序及扩展 → 本机临时签名 → 安装至 `~/Applications/AviaSpectra.app` → 注册并请求启用扩展。

下载失败后可重试原命令，支持断点续传；已完整且校验通过的文件直接复用。首次模型下载约 81 MB。模型打包进应用和扩展后，正常分析不需要联网。

仅想构建：`bash scripts/setup.sh --build-only`。之后可以用 `python3 scripts/manage.py install` 安装。

已有同标识的 AviaSpectra 应用会先移到 `~/Library/Application Support/AviaSpectra/Backups/`，然后安装新版本。若目标是不同标识的应用或符号链接，脚本会拒绝覆盖。更新前请关闭旧版 AviaSpectra 和预览窗口。

## 4. 打开并启用

在 Finder 中前往个人文件夹下的“Applications / 应用程序”，打开 AviaSpectra。首次打开不会自动选择音频，点击“打开其它音频…”试用。

随后在 Finder 选中 MP3 或 WAV，按空格。如果仍显示系统播放器，在系统设置中搜索“Quick Look”“快速查看”或“扩展”，启用 AviaSpectra。不同 macOS 版本的位置和名称可能不同。

检查注册状态：`python3 scripts/manage.py status`。重新请求启用：`python3 scripts/manage.py enable`。关闭旧预览再打开。命令成功不等于界面验收成功，必须实际看到声谱并测试播放。

源码本机构建使用临时签名，不是公证版分发。若被系统拦截，核对来源和本机构建结果，参照系统给出的单应用处理界面；不要关闭全局 Gatekeeper，也不要批量移除文件隔离属性。



安装后可直接使用项目自带的 [samples 真实鸟鸣](../samples/README.md)，无需另行下载音频。

## 5. 验收

使用你有权使用的本地 MP3 和 WAV，分别检查：

1. 空格打开声谱并自动播放。
2. 识别完成出现候选，或明确显示未检出可靠候选。
3. 两轴缩放，拖出选框，点击“识别选框”。
4. 点击“返回整体”，选框消失，完整声谱与整段候选恢复。
5. 地点设置和物种链接可用；错误物种需人工核实。
6. 原文件未被修改。

## 停用与卸载

- 停用：`python3 scripts/manage.py disable`
- 恢复：`python3 scripts/manage.py enable`
- 卸载：先关闭应用和预览，再运行 `python3 scripts/manage.py uninstall`

卸载只将本版应用移入废纸篓，不删除音频、项目源码、模型下载缓存、偏好和推断缓存。无需 sudo，也没有后台服务需要停用。
