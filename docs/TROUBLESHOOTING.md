# 常见问题

[English](TROUBLESHOOTING.en.md)


| 现象 | 处理 |
|---|---|
| 找不到 xcrun / swiftc | 运行 `xcode-select --install`，完成工具安装后重新检查 |
| 提示 Intel 或 Rosetta | 首版仅支持 Apple Silicon 原生运行；不要强行安装 Intel 版本依赖 |
| 下载慢或中断 | 重跑 setup 原命令；已校验文件复用，未完成文件尝试续传。持续60秒低于1KB/s会中止当次传输并按限额重试，失败会明确退出，之后可再次运行。先确认可以访问官方 GitHub Raw / PyPI |
| curl 报不支持断点续传 | 仅删除报错文件对应的 `.dependencies/文件名.part` 后重试，从头下载；不要删除用户音频 |
| SHA-256 不匹配 | 脚本会停止并移除损坏的 partial。重新下载；不要关闭校验 |
| 编译报 SDK / availability | 保存完整错误，核对开发工具版本与 VALIDATION.md，提交 Issue；不要虚报旧系统兼容 |
| Finder 仍是音乐播放器 | 关闭预览，打开 AviaSpectra 一次，检查系统设置的 Quick Look 扩展及 `manage.py status`，重新 enable |
| 已识别选框但想看整段 | 点“返回整体”；全览/双击只重置缩放 |
| 地点筛选后没有结果 | 检查是否为录音地点，可切回全球比较；地理先验可能排除迷鸟 |
| 无候选 | 不代表没有鸟鸣；可能信噪比低、模型不覆盖、框太短/频带太窄或阈值限制 |
| 找不到模型 | 重新运行 fetch 和 build；不要移动 app 内部文件或改名模型 |
| 签名失效 | 完整重新本机构建。不要修改已签名 app 的 Contents；不关闭系统安全机制 |
| 链接打不开 | 网站/网络或分类命名变化；推断不依赖网站。可手动搜索拉丁名 |

## 旧原型与其他扩展

本版标识为 `local.aviaspectra.preview.quicklook`，旧 BirdScope 原型为 `local.birdscope.preview.prototype.quicklook`。安装器不会更改旧原型。若你确实安装过旧原型并决定换成本版，可以先停用旧原型：

```sh
pluginkit -e ignore -i local.birdscope.preview.prototype.quicklook
python3 scripts/manage.py enable
```

只在用户明确选择切换时执行。其他音频 Quick Look 扩展的优先级也可能影响显示，应该通过系统设置选择，不要批量注销所有扩展或终止 Finder。

## 报告问题

填写 Issues 模板，提供芯片、macOS 版本、开发工具版本、出错阶段和已去除个人路径的日志。不要上传凭证或未经许可的录音。合成测试可以运行 `python3 tests/smoke.py`。
