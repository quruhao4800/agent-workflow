# quruhao-skills

团队 AI 辅助开发配置仓库（Java / Spring Boot 向）。综合了 [obra/superpowers](https://github.com/obra/superpowers) 的流程纪律和 [everything-claude-code](https://github.com/affaan-m/everything-claude-code) 的语言领域知识中**成熟可靠的部分**，后续独立维护和扩展。

---

## 目录结构

```
quruhao-skills/
│
├── skills/                                  # Agent 技能库（18 个 skills）
│   ├── workflow/                            # 🔄 开发流程（4）
│   │   ├── brainstorming/                   #   设计对齐（问答→spec→确认）
│   │   ├── writing-plans/                   #   精确 task 拆解
│   │   ├── executing-plans/                 #   分批执行 + 检查点（小计划）
│   │   └── subagent-driven-development/     #   subagent 独立执行 + 双阶段 review（大计划）
│   │
│   ├── testing/                             # 🧪 测试（2）
│   │   ├── test-driven-development/         #   RED → GREEN → REFACTOR（Java/JUnit 5）
│   │   └── java-testing/                    #   Java 测试模式
│   │
│   ├── debugging/                           # 🔍 调试与验证（2）
│   │   ├── systematic-debugging/            #   四阶段根因分析
│   │   └── verification-before-completion/  #   完成前必须贴证据
│   │
│   ├── collaboration/                       # 🤝 协作与 Git（3）
│   │   ├── requesting-code-review/          #   发起 review 自检清单
│   │   ├── receiving-code-review/           #   处理 review 反馈
│   │   └── finishing-a-development-branch/  #   merge / PR / 清理
│   │
│   ├── languages/                           # 💻 语言与基础设施（5）
│   │   ├── springboot-patterns/             #   Spring Boot 最佳实践
│   │   ├── api-design/                      #   REST API 设计（Java 示例）
│   │   ├── database-migrations/             #   数据库迁移（Flyway）
│   │   ├── redis-patterns/                  #   Redis 缓存、锁、流（Redisson）
│   │   └── logging-standards/              #   日志规范
│   │
│   └── meta/                                # ⚙️ 元技能（2）
│       ├── using-superpowers/               #   THE RULE: 强制 skill 检查
│       └── security-review/                 #   安全审查流程（Spring Boot）
│
├── rules/                                   # 硬性约束
│   └── common/                              #   coding-style, git-workflow, security, testing,
│                                            #   performance, patterns, agents, hooks, dev-workflow
│
├── agents/                                  # 专用 subagent（6 个）
│   ├── code-reviewer.md                     #   代码审查
│   ├── architect.md                         #   架构决策
│   ├── planner.md                           #   任务规划
│   ├── tdd-guide.md                         #   TDD 指导
│   ├── security-reviewer.md                 #   安全审查
│   └── build-error-resolver.md              #   构建错误修复
│
├── hooks/                                   # 会话钩子
├── lib/                                     # 工具函数（skill 发现和加载）
├── docs/                                    # 平台文档与计划
├── .claude-plugin/plugin.json               # Claude Code 插件清单
├── .opencode/                               # OpenCode 适配
├── .codex/                                  # Codex 适配
├── .cursor-plugin/                          # Cursor 适配
└── install.sh                               # 团队成员安装脚本
```

---

## 核心工作流

由 `skills/meta/using-superpowers/` 驱动：

> **THE RULE**: 哪怕 1% 的可能性某个 skill 适用，agent 必须先调用检查。不可商量。

```
"Let's build X"
  → workflow/brainstorming          设计问答 → spec
  → workflow/writing-plans          拆为 task
  → workflow/subagent-driven-development
      ├─ 实现者 subagent
      ├─ spec compliance review
      └─ code quality review
  → testing/test-driven-development RED → GREEN → REFACTOR
  → debugging/verification-before-completion  贴出证据
  → collaboration/finishing-a-development-branch

"Fix this bug"
  → debugging/systematic-debugging
      Phase 1~4: 日志→证据→假说→修复
      ⚠ 3 次失败 → 质疑架构
```

---

## 安装与使用

### Claude Code（推荐）

```bash
git clone <repo-url> D:/yourpath/quruhao-skills
# 在 Claude Code 中:
/plugin install --path D:/yourpath/quruhao-skills
```

或直接通过目录链接读取（Windows Junction）：

```powershell
# 修改 ~/.claude/plugins/installed_plugins.json 中 installPath 指向项目目录
```

### OpenCode

```bash
git clone <repo-url> ~/.config/opencode/quruhao-skills
mkdir -p ~/.config/opencode/plugins ~/.config/opencode/skills

ln -sf ~/.config/opencode/quruhao-skills/.opencode/plugins/quruhao-skills.js \
       ~/.config/opencode/plugins/quruhao-skills.js
ln -sfn ~/.config/opencode/quruhao-skills/skills \
        ~/.config/opencode/skills/phoenix
# 重启 OpenCode
```

### Codex (OpenAI)

```bash
git clone <repo-url> ~/.codex/quruhao-skills
mkdir -p ~/.agents/skills
ln -sfn ~/.codex/quruhao-skills/skills ~/.agents/skills/phoenix
# 重启 Codex
```

### Cursor / Windsurf

```bash
cd ~/your-project
cat ~/quruhao-skills/rules/common/*.md > .cursorrules
cp .cursorrules .windsurfrules
```

### GitHub Copilot

```bash
cat ~/quruhao-skills/rules/common/*.md > .github/copilot-instructions.md
```

---

## 跨平台能力

| 能力 | Claude Code | OpenCode | Codex | Cursor/Windsurf |
|------|:-----------:|:--------:|:-----:|:---------------:|
| Skill 自动发现 | ✅ | ✅ | ✅ | ❌ |
| 完整 workflow | ✅ | ✅ | ⚠️ | ❌ |
| Subagent review | ✅ | ✅ | ⚠️ | ❌ |
| Session hooks | ✅ | ✅ | ❌ | ❌ |
| Rules 约束 | ✅ | ✅ | ✅ | ✅ |

---

## 扩展指南

### 新增 Skill

文件格式：

```markdown
---
name: my-skill
description: >
  Use when [触发条件]. [做什么].
---

# Skill 标题

[具体指令]
```

放到对应目录即自动发现：

| 类型 | 目录 |
|------|------|
| 流程 | `skills/workflow/` |
| 测试 | `skills/testing/` |
| 调试 | `skills/debugging/` |
| 协作 | `skills/collaboration/` |
| 语言/框架/基础设施 | `skills/languages/` |
| 控制 agent 行为 | `skills/meta/` |

### 新增 Rules

在 `rules/common/` 下创建 `.md` 文件。格式参考现有 rules（短而精炼，每条 20-50 行）。

### 新增 Agent

在 `agents/` 下创建 `.md`，格式：

```markdown
---
name: my-agent
description: [何时使用]
tools: ["Read", "Grep", "Bash"]
model: sonnet
---

[角色定义和指令]
```

---

## License

MIT
