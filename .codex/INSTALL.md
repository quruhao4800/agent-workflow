# agent-workflow — Codex (OpenAI) 安装

```bash
# 1. 克隆
git clone <repo-url> ~/.codex/agent-workflow

# 2. 创建 skills symlink
mkdir -p ~/.agents/skills
ln -sfn ~/.codex/agent-workflow/skills ~/.agents/skills/agent-workflow

# 3. 重启 Codex
```

## Windows (PowerShell)

```powershell
git clone <repo-url> "$env:USERPROFILE\.codex\agent-workflow"
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.agents\skills"
cmd /c mklink /J "$env:USERPROFILE\.agents\skills\agent-workflow" `
  "$env:USERPROFILE\.codex\agent-workflow\skills"
```

## 工作原理

- Codex 启动时扫描 `~/.agents/skills/` 目录
- 解析每个 `SKILL.md` 的 YAML frontmatter（name + description）
- 根据 description 自动判断何时激活 skill
- `using-superpowers` skill 自动发现并强制 skill 使用纪律

## 更新

```bash
cd ~/.codex/agent-workflow && git pull
# Symlink 自动生效
```

## 卸载

```bash
rm -f ~/.agents/skills/agent-workflow
rm -rf ~/.codex/agent-workflow
```
