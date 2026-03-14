# 方案复盘：老 Linux 上把 Codex Desktop 跑起来，我们到底解决了什么

这份文档是面向仓库维护者和后来者的技术复盘，解释这条方案为什么成立。

## 目标

在不升级宿主机 Ubuntu 20.04 内核、不全局替换系统编译器的前提下，让 Codex Desktop 在 Linux 上可构建、可启动、可进入桌面环境使用。

## 真实遇到的问题链路

### 1. 旧版 `p7zip` 解不开当前官方 DMG

现象：
- Ubuntu 20.04 默认 `7z` 无法识别新版 `Codex.dmg`

结论：
- 这是宿主机解包工具过旧，不是仓库逻辑错

最终处理：
- `install.sh` 优先使用仓库内较新的 `7zz`
- 即使 DMG 中的 `/Applications` 符号链接导致 7-Zip 非零退出，也允许继续，只要 `Codex.app` 已被成功解出

### 2. 宿主机 GCC 9.4 太旧，Electron 40 原生模块无法重编译

现象：
- `better-sqlite3`
- `node-pty`

在 Ubuntu 20.04 默认 `g++ 9.4` 环境下无法完成重编译，最终卡在 C++20 相关头文件和标准库能力上。

结论：
- 直接走宿主机构建不是通用可复制方案

最终处理：
- 不把“升级宿主机 GCC”作为主方案
- 把原生模块编译移入 Docker 容器

### 3. Ubuntu 24.04 容器虽然能编出来，但回到 Ubuntu 20.04 运行会炸

现象：
- 原生模块在新容器里链接到了更高版本的 glibc
- 回到 Ubuntu 20.04 宿主机运行时报 `GLIBC_2.38 not found`

结论：
- 构建环境不能比目标运行环境更新太多
- “能编过”不等于“能在老系统上跑”

最终处理：
- Docker 基础镜像固定到 `ubuntu:20.04`
- 原生模块也在 Ubuntu 20.04 glibc 基线下构建

### 4. Ubuntu 20.04 自带 GCC 太旧，但容器里仍然需要现代编译器

现象：
- 目标运行环境必须老
- 编译器能力又必须新

结论：
- 最合理的折中不是升级宿主机，而是在 Ubuntu 20.04 容器里单独装新编译器

最终处理：
- 容器内使用 `clang-18` + `libc++`
- 同时把 `libc++`、`libc++abi`、`libunwind` 打包到最终 `codex-app/runtime-libs/`
- `start.sh` 通过 `LD_LIBRARY_PATH` 在宿主机运行时优先加载这些库

### 5. 黑屏并不是“应用没起来”，而是 Linux + NVIDIA + Electron 透明窗口兼容问题

现象：
- 日志显示窗口已 `ready-to-show`
- 页面内容实际上已经加载
- 但在宿主机上看到的是黑屏

结论：
- 不是 CLI 没连上，也不是前端页面没加载
- 是 Electron 在 Linux 下透明背景和桌面合成器交互不稳定，尤其在 `Ubuntu 20.04 + X11 + NVIDIA` 上更明显

最终处理：
- 对 Electron 主进程 bundle 加 Linux 不透明窗口背景补丁
- 不再建议用 `--disable-gpu` 硬绕，因为当前应用会要求 GPU 可用

## 最终稳定方案

最终稳定可复用的方案是：
- 用 `ubuntu:20.04` 容器构建
- 在容器里用 `clang-18` + `libc++` 重编译原生模块
- 把 `libc++` 运行时库打包到最终应用
- 在 Linux 下对 Electron 主窗口强制使用不透明背景
- 在宿主机创建图标、应用菜单入口、桌面快捷方式

对应的仓库入口是：
- `one-click-install.sh`
- `build-in-docker.sh`

## 为什么这条方案适合公开帮助别人

因为它具备下面几个特点：
- 不要求升级内核
- 不要求升级发行版
- 不要求改系统默认 `gcc/g++`
- 不要求用户理解原生模块 ABI、glibc、Electron 黑屏这些底层问题
- 对 Ubuntu 20.04 这类“想保持稳定但又想用桌面版 Codex”的用户很友好

## 现在这个仓库已经内置的关键能力

- DMG 兼容解包
- Ubuntu 20.04 兼容 Docker 构建路径
- `clang-18` + `libc++` 原生模块重编译
- `libc++` 运行时库打包
- Linux 黑屏修补
- 应用菜单图标
- GNOME `Add to Favorites` 兼容
- 桌面快捷方式
- 一键入口脚本

## 建议对外如何描述这个项目

一句话版本：

> A one-click way to run Codex Desktop on Ubuntu 20.04 and other older Linux hosts without upgrading the kernel or replacing the system compiler.

中文版本：

> 一个面向 Ubuntu 20.04/老 Linux 的 Codex Desktop 一键解决方案，不需要升级内核，也不需要替换系统默认编译器。
