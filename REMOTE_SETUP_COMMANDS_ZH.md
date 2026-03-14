# 远端配置命令

当前本地仓库已经完成：
- `git init`
- 首个提交
- 默认分支切换为 `main`

当前首个提交：

```bash
git log --oneline -1
```

## 如果你使用 HTTPS

把下面的 `<your-repo-url>` 替换成你的远端地址：

```bash
git remote add origin <your-repo-url>
git push -u origin main
```

示例：

```bash
git remote add origin https://github.com/yourname/codex-desktop-linux-one-click.git
git push -u origin main
```

## 如果你使用 SSH

```bash
git remote add origin git@github.com:yourname/codex-desktop-linux-one-click.git
git push -u origin main
```

## 如果你已经加过远端但想改地址

```bash
git remote set-url origin <your-repo-url>
git push -u origin main
```

## 检查远端是否配置成功

```bash
git remote -v
git branch -vv
```
