# 推远端前清单

如果你准备把这个仓库推到 GitHub 或其他远端，建议按下面顺序检查。

## 1. 不要把官方桌面二进制重新分发出去

这个仓库的定位应该是：
- 自动化转换脚本
- Docker 构建路径
- 文档
- 社区图标和桌面集成

不建议提交到远端的内容：
- `Codex.dmg`
- `codex-app/`
- `.docker-home/`

这些文件已经在 `.gitignore` 里忽略。

## 2. 当前仓库推荐对外入口

对外文档里优先写：

```bash
./one-click-install.sh
```

不要再把“升级宿主机 GCC 12/13”写成主方案。

## 3. 推荐放到仓库首页的重点卖点

建议直接写清楚：
- Ubuntu 20.04 兼容
- 老 Linux 兼容
- 不需要升级内核
- 不需要替换系统默认编译器
- 修复 Electron 黑屏
- 自动创建应用菜单图标和桌面快捷方式

## 4. 建议保留的核心文件

- `README.md`
- `README_ZH.md`
- `one-click-install.sh`
- `build-in-docker.sh`
- `install.sh`
- `Dockerfile`
- `DOCKER_USAGE.md`
- `SOLUTION_REVIEW_ZH.md`
- `DEPLOYMENT_FAILURE_REPORT.md`
- `assets/codex-desktop.png`
- `LICENSE`

## 5. 建议的仓库说明文案

英文一句话：

> One-click Codex Desktop for Ubuntu 20.04 and older Linux hosts, without upgrading the kernel or replacing the system compiler.

中文一句话：

> 面向 Ubuntu 20.04/老 Linux 的 Codex Desktop 一键解决方案，不升级内核，不替换系统默认编译器。

## 6. 如果你要初始化 Git 并推到远端

如果这是一个全新的本地目录，可以用：

```bash
git init
git add .
git commit -m "feat: one-click Codex Desktop for Ubuntu 20.04 and older Linux"
```

添加远端后：

```bash
git branch -M main
git remote add origin <your-repo-url>
git push -u origin main
```

## 7. 推送前建议最后人工确认一次

重点确认：
- `git status` 里没有 `Codex.dmg`
- `git status` 里没有 `codex-app/`
- README 顶部写的是 `one-click-install.sh`
- 文档里没有把“升级宿主机 GCC”写成当前首选路径
- 文档里已经写明这是 unofficial community project

## 8. 推荐仓库名思路

如果你想让别人一眼知道它解决什么问题，仓库名可以考虑：
- `codex-desktop-linux-one-click`
- `codex-desktop-ubuntu20`
- `codex-desktop-linux-compat`

其中我最推荐：
- `codex-desktop-linux-one-click`
