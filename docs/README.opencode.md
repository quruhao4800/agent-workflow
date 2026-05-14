# quruhao-skills — OpenCode 使用指南

## 安装

详见 `.opencode/INSTALL.md`。

## 架构

quruhao-skills 通过两个机制与 OpenCode 集成：

### 1. 插件（System Prompt 注入）

`.opencode/plugins/quruhao-skills.js` 通过 `experimental.chat.system.transform` hook 在每次请求时将 `using-superpowers` 元技能注入 system prompt，确保 agent 在每次对话中都遵循 skill 检查纪律。

### 2. Skills（原生 Skill Tool）

Skills 通过 symlink 映射到 `~/.config/opencode/skills/quruhao-skills/`，由 OpenCode 原生 skill tool 发现和加载。每个 skill 的 `SKILL.md` 包含 YAML frontmatter，OpenCode 据此判断何时激活。

### Tool 映射

Skills 中引用的 Claude Code 工具在 OpenCode 中的对应关系：

| Claude Code | OpenCode |
|-------------|----------|
| `TodoWrite` | `update_plan` |
| `Task` (subagent) | `@mention` subagent |
| `Skill` | 原生 `skill` tool |
| `Read`, `Write`, `Edit`, `Bash` | 同名原生工具 |

### 自定义 Skills

在 `~/.config/opencode/skills/` 下创建个人 skill 目录：

```
~/.config/opencode/skills/
├── quruhao-skills/          → symlink 到 quruhao-skills/skills/
└── my-skills/        → 你的个人 skills
    └── my-skill/
        └── SKILL.md
```

个人 skills 优先级高于 quruhao-skills skills。
