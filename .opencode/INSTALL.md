# quruhao-skills — OpenCode 安装

```bash
# 1. 克隆到 OpenCode 配置目录
git clone <repo-url> ~/.config/opencode/quruhao-skills

# 2. 创建目录
mkdir -p ~/.config/opencode/skills

# 3. 创建 skills symlink
ln -sfn ~/.config/opencode/quruhao-skills/skills \
        ~/.config/opencode/skills/quruhao-skills

# 4. 重启 OpenCode
```

## 工作原理

- Skills 通过 OpenCode 原生 skill tool 发现，解析 SKILL.md 的 YAML frontmatter
- 命名空间前缀: `quruhao-skills:golang-patterns`, `quruhao-skills:systematic-debugging`
- 优先级: project skills > personal skills > quruhao-skills skills

## 更新

```bash
cd ~/.config/opencode/quruhao-skills && git pull
# Symlink 自动生效，无需额外操作
```

## 验证

```bash
ls ~/.config/opencode/skills/quruhao-skills/
```

## 卸载

```bash
rm -f ~/.config/opencode/skills/quruhao-skills
rm -rf ~/.config/opencode/quruhao-skills
```
