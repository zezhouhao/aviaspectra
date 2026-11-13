# AI 协助安装协议

[English](AI_INSTALL.en.md)


适用于能读取本项目并执行本机终端命令的 AI 编程工具。普通用户可把本文件交给 AI。所有命令都在仓库根目录执行。

## 工作范围

按用户授权完成本机源码构建、安装和 Quick Look 启用；不需要 Apple Developer Program、API Key 或上传音频。请先说明将下载模型、编译并注册当前用户扩展。不要修改原始音频或其他下载/分析程序。

## 顺序

1. 阅读 README、AGENTS.md、INSTALL.md 和 VALIDATION.md，核对当前限制。
2. 执行 `python3 scripts/doctor.py`。如果开发工具未安装，指导用户完成 `xcode-select --install`；不要代替用户接受许可或处理凭证。Intel / Rosetta 环境应停止，不猜测兼容性。
3. 阅读 `scripts/setup.sh`、`fetch_dependencies.py`、`build.py`、`manage.py`。运行 `bash scripts/setup.sh`；若用户只授权构建，则添加 `--build-only`，不注册扩展。
4. 模型和运行库仅从 `dependencies/manifest.json` 指定的官方来源下载。网络中断重试；哈希失败不要绕过校验、关闭 TLS 或换未核验的镜像。模型文件名不同不代表版本可互换。
5. 执行 `python3 tests/smoke.py`，检查签名、最低系统版本和本地推断。此检查会在 build/tests 中产生合成音频；不会触碰用户音频。
6. 查看 `python3 scripts/manage.py status`。请用户打开 AviaSpectra 一次，再在 Finder 选音频按空格；如未显示，按 TROUBLESHOOTING.md 处理。需要系统设置开关时指导用户操作。不要声称 pluginkit 返回成功就代表 Finder 已验证。
7. 使用用户授权的音频验证 MP3/WAV、自动播放、双轴缩放、选框识别、返回整体、地点筛选及链接。无本地音频时使用 `python3 tests/make_fixtures.py` 生成 WAV；它是合成信号，不应该被描述成真实鸟声。
8. 交付安装路径、已验证/未验证项目、当前限制和停用/卸载命令。

## 故障处理边界

- 如果 AI 工具的执行沙盒拒绝 macOS 图像/音频服务，按工具的权限流程请求当前构建或测试命令所需权限；不要改写系统安全设置。
- 不执行 `sudo`、全局安全机制关闭、批量 xattr 清除、关闭 SIP 或杀死 Finder。
- 不覆盖未知应用；安装器会核对 bundle ID 并备份同版应用。
- 不自动停用其他音频预览扩展；先报告冲突，让用户选择。
- 不安装后台 LaunchAgent、HTTP 识别服务或 Python 虚拟环境。本版推断为原生 LiteRT。
- 不把私有音频、日志中的个人路径、Token 或凭证提交 GitHub。
- 不把模型评分称作准确率，不声称地理过滤一定提高正确率。
- 新系统或干净账户尚未测试时，明确记录结果；不要复制原作者的验证结论当作本机结果。

## 给使用者的完成说明模板

“已安装至……；已验证……；仍需你确认……。停用运行……，卸载运行……。本版仅预览前120秒，模型候选需复听核实。”
