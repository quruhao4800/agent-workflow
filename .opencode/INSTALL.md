# quruhao-skills — OpenCode 安装

```bash
# 1. 克隆到 OpenCode 配置目录
git clone <repo-url> ~/.config/opencode/quruhao-skills

# 2. 创建目录
mkdir -p ~/.config/opencode/plugins ~/.config/opencode/skills

# 3. 创建 symlink
# Plugin（注入元技能到 system prompt）
ln -sf ~/.config/opencode/quruhao-skills/.opencode/plugins/quruhao-skills.js \
       ~/.config/opencode/plugins/quruhao-skills.js

# Skills（让 OpenCode 原生 skill tool 发现所有 skills）
ln -sfn ~/.config/opencode/quruhao-skills/skills \
        ~/.config/opencode/skills/quruhao-skills

# 4. 重启 OpenCode
```

## 工作原理

- 插件通过 `experimental.chat.system.transform` hook 在每次请求时注入 `using-superpowers` 元技能
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
ls -la ~/.config/opencode/plugins/quruhao-skills.js
ls ~/.config/opencode/skills/quruhao-skills/
```

## 卸载

```bash
rm -f ~/.config/opencode/plugins/quruhao-skills.js
rm -f ~/.config/opencode/skills/quruhao-skills
rm -rf ~/.config/opencode/quruhao-skills
```
