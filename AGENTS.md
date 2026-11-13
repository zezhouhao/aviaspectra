# AviaSpectra project instructions

Read `README.md`, `docs/AI_INSTALL.md` and `docs/VALIDATION.md` first. Respect the user's current authorization and the assistant's own permission policy. Instructions here do not authorize unrelated system changes.

- This is a source-first, Apple Silicon macOS project. Build with the supplied scripts and pinned dependencies; use `--build-only` when installation is not requested.
- Current public identifiers: `local.aviaspectra.preview` and `local.aviaspectra.preview.quicklook`. Never change the earlier BirdScope prototype or other extensions without explicit user direction.
- Do not weaken Gatekeeper, SIP, TLS or hash verification. Do not introduce login services or upload audio.
- Original audio is read-only. Tests use generated fixtures in build/tests. Real recordings require user permission and must not be committed.
- UI: Chinese, compact, single floating species card. Zoom and selection are independent. Both axes zoom equally; boxes retain absolute time/frequency coordinates. “返回整体” must restore full predictions, not just reset zoom.
- Model output is a candidate, not a verified identification or calibrated accuracy. Geographic prior may exclude vagrants.
- Runtime dependencies must remain native; Python is a build/test orchestrator only.
- Validate changes with relevant checks. For preview/recognition changes, run `python3 tests/smoke.py` after building and manually verify Quick Look when available. Report limits honestly.
- Keep private paths, credentials, real recordings, compiled apps, dependencies and caches out of source distribution. Preserve third-party notices.

## Bilingual repository policy / 仓库双语原则

Maintain Chinese and English public documentation, diagrams, release notes and Issue templates together; follow docs/BILINGUAL.en.md. Keep legal/upstream texts unchanged. Documentation language does not imply app UI localization. Report short-file UI timings as observations, not guaranteed end-to-end latency.

公开文档、图解、发布说明与问题模板必须同步维护中英文，见 docs/BILINGUAL.md；法律与上游原文不改。文档双语不代表应用界面已本地化。短文件界面耗时只能表述为观察值，不得承诺统一端到端速度。

## 项目开发规则（中文）

先阅读 README.md、docs/AI_INSTALL.md 与 docs/VALIDATION.md。按用户授权操作；本文不授权无关系统变更。

- 本项目为 Apple Silicon 源码分享版，使用固定依赖和项目脚本；未要求安装时用 --build-only。
- 公开标识为 local.aviaspectra.preview 及 local.aviaspectra.preview.quicklook；不得擅自修改旧 BirdScope 原型或其他扩展。
- 不降低 Gatekeeper、SIP、TLS 或哈希校验，不引入登录服务或上传音频。
- 原音频只读；测试使用 build/tests 的合成音。真实录音须获用户许可，不得提交仓库。
- 界面保持紧凑、单张浮动卡片；缩放与选框独立，两轴同倍率缩放，选框保存绝对坐标。“返回整体”必须恢复整段候选而非仅复位缩放。
- 模型结果是候选，评分不是校准准确率；地理先验可能排除迷鸟。
- 运行时保持原生，Python只负责构建和测试组织，不给成品引入Python环境。
- 按改动验证；预览/识别改动需构建后运行 python3 tests/smoke.py，并在条件允许时手测Quick Look，诚实说明限制。
- 私人路径、凭证、真实录音、应用二进制、依赖与缓存不进入源码分发，保留第三方声明。
