# agent-workflow

通用 Agent Coding Workflow Kit——将 brainstorm → plan → execute → review 流程纪律固化为可复用 skill，让 AI 编码助手在任何项目中保持一致的工程规范。**Java / Spring Boot 是第一个深度适配的语言包**，其他语言欢迎社区贡献。综合了 [obra/superpowers](https://github.com/obra/superpowers) 的流程纪律和 [everything-claude-code](https://github.com/affaan-m/everything-claude-code) 的语言领域知识中**成熟可靠的部分**，后续独立维护和扩展。

---

## 目录结构

```
agent-workflow/
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
├── docs/                                    # 平台文档与计划
├── .claude-plugin/plugin.json               # Claude Code 插件清单
├── .opencode/                               # OpenCode 适配
├── .codex/                                  # Codex 适配
├── .cursor-plugin/                          # Cursor 适配
└── install.ps1                              # Windows 安装脚本（创建 Junction）
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

> **已验证平台：Windows 11。** Mac / Linux 用户请参考 [Claude Code 官方文档](https://docs.anthropic.com/claude-code) 中的插件安装说明，欢迎 PR 贡献其他平台的安装脚本。

**Windows（推荐使用安装脚本）：**

```powershell
git clone <repo-url> D:/yourpath/agent-workflow
cd D:/yourpath/agent-workflow
.\install.ps1
# 重启 Claude Code 生效
```

项目内置 `.claude/settings.json` 是**有意提交的推荐权限文件**，包含工作流所需的 `WebSearch`、`git *` 等权限。**安装前请审查该文件内容**，根据个人安全策略决定是否保留全部条目。

**手动安装（Windows Junction）：**

```powershell
git clone <repo-url> D:/yourpath/agent-workflow
New-Item -ItemType Junction `
  -Path "$env:USERPROFILE\.claude\plugins\cache\local\agent-workflow\1.0.0" `
  -Target "D:/yourpath/agent-workflow"
# 重启 Claude Code 生效
```

### OpenCode

```bash
git clone <repo-url> ~/.config/opencode/agent-workflow
mkdir -p ~/.config/opencode/skills

ln -sfn ~/.config/opencode/agent-workflow/skills \
        ~/.config/opencode/skills/agent-workflow
# 重启 OpenCode
```

### Codex (OpenAI)

```bash
git clone <repo-url> ~/.codex/agent-workflow
mkdir -p ~/.agents/skills
ln -sfn ~/.codex/agent-workflow/skills ~/.agents/skills/agent-workflow
# 重启 Codex
```

### Cursor / Windsurf

```bash
cd ~/your-project
cat ~/agent-workflow/rules/common/*.md > .cursorrules
cp .cursorrules .windsurfrules
```

### GitHub Copilot

```bash
cat ~/agent-workflow/rules/common/*.md > .github/copilot-instructions.md
```

---

## 跨平台能力

| 能力 | Claude Code | OpenCode | Codex | Cursor/Windsurf |
|------|:-----------:|:--------:|:-----:|:---------------:|
| Skill 自动发现 | ✅ | ✅ | ✅ | ❌ |
| 完整 workflow | ✅ | ⚠️ | ⚠️ | ❌ |
| Subagent review | ✅ | ✅ | ⚠️ | ❌ |
| Session hooks | ✅ | ❌ | ❌ | ❌ |
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
