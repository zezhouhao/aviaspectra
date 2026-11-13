# LiteRT C API headers

Headers under `litert/c/` were obtained from `https://raw.githubusercontent.com/google-ai-edge/LiteRT/v2.3.0/` followed by the same repository path. Their original Apache 2.0 copyright notices are preserved. License: `../Notices/LiteRT-LICENSE.txt`.

`litert/build_common/build_config.h` is a locally generated empty include guard required by the C headers when used outside the upstream Bazel build. AviaSpectra only uses the CPU C API and does not enable optional platform APIs. It is not an upstream generated configuration for a full LiteRT build.

Only headers are vendored. The official prebuilt native runtime is fetched and SHA-256 verified by `scripts/fetch_dependencies.py`; the project does not rebuild LiteRT or install its Python package.

## 中文说明

litert/c 中的头文件来自官方 LiteRT v2.3.0，对应上游相同路径；原始 Apache 2.0 版权声明保持不变，许可见 ../Notices/LiteRT-LICENSE.txt。

litert/build_common/build_config.h 是为在上游 Bazel 构建之外使用 C 头文件而生成的最小本地空 include guard。AviaSpectra 只使用 CPU C API，不启用可选平台 API；它不是完整 LiteRT 构建的上游配置文件。

仓库只包含头文件。官方预编译原生运行库由 scripts/fetch_dependencies.py 下载并校验 SHA-256；项目不重建 LiteRT，也不安装其 Python 包。
