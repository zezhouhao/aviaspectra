# Sharing AviaSpectra on GitHub for the first time

[中文](GITHUB_UPLOAD.md)


For the project author. Upload the curated source package, not the entire development directory.

## 1. Create the repository

Sign in at [GitHub](https://github.com), choose **+ → New repository**, name it `aviaspectra`, and choose Public. This package already includes README, .gitignore and LICENSE; do not generate duplicate templates. Use a bilingual description, for example: `按空格查看鸟鸣声谱与本机物种候选 / Space-key bird-audio spectrograms and on-device species candidates.` Then create the repository.

## 2. Upload source

Use **uploading an existing file** for an empty repository or **Add file → Upload files** later. Upload the contents of the local aviaspectra folder so README.md, Sources and scripts are at the repository root, without an extra aviaspectra level.

Show hidden files with Command+Shift+period. In this session Chrome uploaded ordinary files successfully, Safari returned a generic failure, and GitHub's drop zone rejected the hidden .github folder. If it says **This file is hidden**, do not repeatedly drag it or remove the leading dot.

Select .gitignore and .gitattributes through **choose your files**. Commit the ordinary source and those files first. Then use **Add file → Create new file**, entering these complete paths and copying the matching local contents:

- `.github/workflows/build.yml`
- `.github/ISSUE_TEMPLATE/bug_report.md`
- `.github/ISSUE_TEMPLATE/feature_request.md`

Review each before committing. Alternatively use an authorized Git client to preserve the tree. Never put ISSUE_TEMPLATE/workflows directly at the repository root.

Browser limits: 100 files per batch and 25 MiB per file. Bilingual documentation increases the count; check the actual manifest and split batches as needed. Use a bilingual commit message such as `发布首版源码 / Publish AviaSpectra 1.0.0 source release`. If the UI asks for a branch/PR, follow it and merge to main after review. Respect any instruction reserving the final button for the account owner.

Do not upload only a ZIP as one repository file: GitHub needs the extracted source to render documentation and expose code directly.

## 3. Check the result

Verify Chinese/English homepages, images, links and source directories. Check the first Actions run instead of assuming it passed. The workflow reads code and uploads test reports; it does not publish an app. Debug failures from logs without granting unnecessary write permissions.

Use a bilingual About description and topics such as macos, quick-look, birdnet, bioacoustics, spectrogram and ai-assisted-development.

## 4. Publish a release

Use **Releases → Create a new release**, tag `v1.0.0`, target main. Title: `AviaSpectra 1.0.0 — 源码分享版 / Source-first release`. Include both language release notes. When pasting into a Release, replace relative documentation links with full GitHub URLs under the release tag.

Clearly state local source compilation; do not present an ad-hoc-signed local app as a notarized turnkey installer. GitHub provides source ZIP/tar.gz for the tag. Check contents/licenses before publishing. Let the owner complete reserved final actions; never paste passwords/tokens in chat.

## Future topics

Use one repository per independent app. A later ai-projects repository can provide a bilingual index for small apps, research tools and other topics without duplicating source. No organization or separate website is needed now.

References: [Hello World](https://docs.github.com/en/get-started/using-github/hello-world), [uploading files](https://docs.github.com/en/repositories/working-with-files/managing-files/adding-a-file-to-a-repository), [releases](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases).
