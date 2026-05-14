# agent-workflow — OpenCode 安装

```bash
# 1. 克隆到 OpenCode 配置目录
git clone <repo-url> ~/.config/opencode/agent-workflow

# 2. 创建目录
mkdir -p ~/.config/opencode/skills

# 3. 创建 skills symlink
ln -sfn ~/.config/opencode/agent-workflow/skills \
        ~/.config/opencode/skills/agent-workflow

# 4. 重启 OpenCode
```

## 工作原理

- Skills 通过 OpenCode 原生 skill tool 发现，解析 SKILL.md 的 YAML frontmatter
- 命名空间前缀: `agent-workflow:systematic-debugging`, `agent-workflow:springboot-patterns`
- 优先级: project skills > personal skills > agent-workflow skills

## 更新

```bash
cd ~/.config/opencode/agent-workflow && git pull
# Symlink 自动生效，无需额外操作
```

## 验证

```bash
ls ~/.config/opencode/skills/agent-workflow/
```

## 卸载

```bash
rm -f ~/.config/opencode/skills/agent-workflow
rm -rf ~/.config/opencode/agent-workflow
```
