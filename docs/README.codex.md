# agent-workflow — Codex (OpenAI) 使用指南

## 安装

详见 `.codex/INSTALL.md`。

## 架构

Codex 通过原生 skill discovery 机制与 agent-workflow 集成：

### Skill Discovery

Codex 启动时扫描 `~/.agents/skills/` 目录，解析每个 `SKILL.md` 的 YAML frontmatter：

```yaml
---
name: my-skill
description: Use when [condition] - [what it does]
---
```

`description` 字段决定 Codex 何时自动激活该 skill。`using-superpowers` skill 自动发现后强制所有 skill 使用纪律。

### 限制

- Codex 没有 hooks 系统，`using-superpowers` 通过 skill discovery 自动加载（而非 session hook）
- Subagent 支持有限，`subagent-driven-development` 的双阶段 review 可能无法完整执行
- 没有斜杠命令系统，`commands/` 目录不会被加载

### 自定义 Skills

```
~/.agents/skills/
├── agent-workflow/       → symlink 到 agent-workflow/skills/
└── my-skill/
    └── SKILL.md
```
