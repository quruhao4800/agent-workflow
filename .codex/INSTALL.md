# quruhao-skills — Codex (OpenAI) 安装

```bash
# 1. 克隆
git clone <repo-url> ~/.codex/quruhao-skills

# 2. 创建 skills symlink
mkdir -p ~/.agents/skills
ln -sfn ~/.codex/quruhao-skills/skills ~/.agents/skills/quruhao-skills

# 3. 重启 Codex
```

## Windows (PowerShell)

```powershell
git clone <repo-url> "$env:USERPROFILE\.codex\quruhao-skills"
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.agents\skills"
cmd /c mklink /J "$env:USERPROFILE\.agents\skills\quruhao-skills" `
  "$env:USERPROFILE\.codex\quruhao-skills\skills"
```

## 工作原理

- Codex 启动时扫描 `~/.agents/skills/` 目录
- 解析每个 `SKILL.md` 的 YAML frontmatter（name + description）
- 根据 description 自动判断何时激活 skill
- `using-superpowers` skill 自动发现并强制 skill 使用纪律

## 更新

```bash
cd ~/.codex/quruhao-skills && git pull
# Symlink 自动生效
```

## 卸载

```bash
rm -f ~/.agents/skills/quruhao-skills
rm -rf ~/.codex/quruhao-skills
```
