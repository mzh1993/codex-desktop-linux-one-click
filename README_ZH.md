# Codex Desktop for Linux 中文说明

这个仓库的目标很明确：

让 Ubuntu 20.04 这类较老的 Linux 主机，也能尽量低风险地运行 Codex Desktop，而不需要升级内核、升级发行版，或者全局替换系统编译器。

## 最推荐的用法

直接走一键安装：

```bash
chmod +x one-click-install.sh
./one-click-install.sh
```

如果安装完成后想立刻启动：

```bash
./one-click-install.sh --run
```

这个入口默认会走当前最稳的方案：
- 用 Docker 中的 Ubuntu 20.04 构建
- 在容器里用 `clang-18` + `libc++` 重编译 Electron 原生模块
- 给老系统打包运行时依赖
- 在宿主机创建应用菜单图标、桌面快捷方式、GNOME 收藏兼容项

## 这个仓库解决了什么问题

我们今天实际踩到并已经处理过的问题包括：
- Ubuntu 20.04 自带 `p7zip` 太老，无法解包新版 `Codex.dmg`
- Ubuntu 20.04 默认 `gcc/g++ 9.4` 无法完成 Electron 40 原生模块重编译
- 如果直接在 Ubuntu 24.04 容器里构建，产物会依赖更新的 glibc，回到 Ubuntu 20.04 运行时会崩
- 在 `Ubuntu 20.04 + X11 + NVIDIA` 上，Electron 透明窗口会导致桌面版黑屏

当前仓库已经把这些关键修复都并入安装流程。

## 依赖要求

推荐路径只要求：
- Docker
- 网络可用
- 实际启动桌面版时，宿主机 `PATH` 里能找到 `codex`

如果还没装 CLI：

```bash
npm i -g @openai/codex
```

## 安装完成后会得到什么

成功后会生成：
- 桌面程序目录：`codex-app/`
- 应用菜单入口：`~/.local/share/applications/codex-desktop.desktop`
- 图标：`~/.local/share/icons/hicolor/512x512/apps/codex-desktop.png`
- 桌面快捷方式：`~/Desktop/Codex.desktop`

也可以直接从终端启动：

```bash
./codex-app/start.sh
```

## 适合哪些人

如果你符合下面任意一种情况，这个仓库就是给你准备的：
- 不想升级 Ubuntu 20.04 内核
- 不想动系统默认 GCC
- 宿主机工具链比较旧
- 想把 Codex Desktop 做成真正能从应用菜单启动的 Linux 桌面程序

## 重要文件

- `one-click-install.sh`：推荐的一键入口
- `build-in-docker.sh`：稳定的 Docker 构建路径
- `install.sh`：底层 DMG 转换与修补逻辑
- `SOLUTION_REVIEW_ZH.md`：完整问题复盘
- `PUBLISHING_CHECKLIST_ZH.md`：推远端前的清单
- `GITHUB_METADATA_ZH.md`：仓库名、简介、topic 建议
- `RELEASE_NOTES_v0.1.0.md`：首个版本发布说明模板

## 额外说明

- 这个仓库没有把 `Codex.dmg` 和 `codex-app/` 当作源码发布对象；`.gitignore` 已经默认忽略它们
- `assets/codex-desktop.png` 是仓库内自带的社区图标，用来做 Linux 桌面集成，不依赖官方 app 资源二次分发

如果你想把这个仓库推到远端帮助更多人，建议先看：`PUBLISHING_CHECKLIST_ZH.md`
