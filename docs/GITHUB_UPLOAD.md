# 第一次把 AviaSpectra 分享到 GitHub

[English](GITHUB_UPLOAD.en.md)


这是给项目作者的操作说明。这里的文件已经是待上传源码包，不需要把电脑上的整个开发目录上传。

## 第一步：创建账号与项目

1. 打开 https://github.com ，自行注册并登录账号。
2. 右上角 **+ → New repository**。
3. 名称建议 `aviaspectra`。
4. Description 可复制：`按空格查看鸟鸣声谱与本机物种候选 / Space-key bird-audio spectrograms and on-device species candidates.`
5. 选择 **Public**。当前包已有 README、.gitignore 和 LICENSE，新仓库不必另选模板。
6. 点击 **Create repository**。

## 第二步：上传源码文件

空仓库页面点击 **uploading an existing file**；已有 README 的仓库点击 **Add file → Upload files**。

打开本分享包中的 `aviaspectra` 文件夹，把**文件夹内的内容**上传，确保仓库顶层直接出现 README.md、Sources、scripts，而不是再套一层 aviaspectra。

Finder 中按 Command+Shift+. 显示隐藏文件。当前测试中，Chrome 可以上传普通文件，Safari 出现通用失败；GitHub 拖放区拒绝 `.github` 隐藏文件夹。遇到 “This file is hidden” 时不要反复拖放或去掉名称前面的点。

`.gitignore` 和 `.gitattributes` 可通过 **choose your files** 文件选择器单独选择。先提交普通源码和这两个文件，再用 **Add file → Create new file**，输入完整路径 `.github/workflows/build.yml`、`.github/ISSUE_TEMPLATE/bug_report.md` 和 `.github/ISSUE_TEMPLATE/feature_request.md`，从本地同名文件复制内容并逐一检查提交。也可在明确授权后采用 Git 客户端保留完整目录。不要把 ISSUE_TEMPLATE/workflows 错放到仓库根目录。

每批最多100文件、单个文件不超过25 MiB。文件总数可能随双语文档增加，应按实际清单分批核对。

Commit message 输入 `发布 AviaSpectra 1.0.0 源码版 / Publish source release`，点击提交。若界面要求创建分支并提 Pull Request，按提示创建并合并到 main。

**不要只把整个 ZIP 上传成仓库里的一个文件**：那样首页不会展示说明、AI也不容易直接读取源码。ZIP 是交付给你的搬运包，GitHub 里应该是解压后的源码。

## 第三步：检查首页和自动构建

检查：中文首页与 English 入口正常、两种语言图片和链接都可用、Sources/scripts等目录齐全。进入 Actions 查看构建；第一次运行失败时复制日志交给 AI 排查，不需要随意授予写权限。当前 workflow 只读源码并上传测试报告，不发布任何安装包。

在仓库右侧 About 设置 Description 和 Topics，可用：`macos`, `quick-look`, `birdnet`, `bioacoustics`, `spectrogram`, `ai-assisted-development`。

## 第四步：发布第一个版本

仓库右侧 **Releases → Create a new release**，新建标签 `v1.0.0`，目标 main。标题 `AviaSpectra 1.0.0 — 源码分享版 / Source-first release`。

正文同时包含 docs/RELEASE_NOTES_v1.0.0.md 和对应的 .en.md 内容；粘贴到 Release 页面时将相对文档链接改为对应标签下的完整 GitHub 链接。明确是本机源码构建；不要把本机临时签名 app 当作免配置安装包。GitHub 会为标签提供源码 ZIP / tar.gz，用户可下载后按照安装指南操作。

正式点击发布前检查文件内容和许可。没有上传或发布权限时让账号持有人完成，不在聊天中粘贴密码或 Token。

## 后续专题

建议每个可独立使用的项目一个仓库。将来可另建 `ai-projects`，用 README 作为专题目录，分为“小应用开发与部署”“数据分析”等栏目，链接到 AviaSpectra 和其他项目。现在无需创建组织或网站。

官方参考：
- https://docs.github.com/en/get-started/using-github/hello-world
- https://docs.github.com/en/repositories/working-with-files/managing-files/adding-a-file-to-a-repository
- https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases
