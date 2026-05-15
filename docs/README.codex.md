# agent-workflow — Codex (OpenAI) 使用指南

## 安装

详见 `.codex/INSTALL.md`。

## 架构

Codex 没有原生 skill 发现机制（无 `~/.agents/skills/` 扫描），通过 `AGENTS.md` 注入 rules 内容与 agent-workflow 集成。

### 接入方式

将 `rules/common/` 下的所有规则合并到项目根目录的 `AGENTS.md`：

```bash
cat ~/agent-workflow/rules/common/*.md > AGENTS.md
```

Codex 启动时读取该文件，将其作为 agent 的系统指令。

### 限制

| 能力 | 支持 |
|------|:----:|
| Rules 约束 | ✅ |
| Skill 自动发现 | ❌ |
| 完整 workflow | ❌ |
| Subagent review | ❌ |
| Session hooks | ❌ |

### 自定义

如需将特定 skill 内容也注入进去，可手动追加：

```bash
cat ~/agent-workflow/rules/common/*.md \
    ~/agent-workflow/skills/debugging/systematic-debugging/SKILL.md \
    > AGENTS.md
```
