# agent-workflow — Codex (OpenAI) 安装

Codex 没有原生 skill 发现机制，通过 `AGENTS.md` 注入 rules 内容。

```bash
cd ~/your-project
cat ~/agent-workflow/rules/common/*.md > AGENTS.md
```

## Windows (PowerShell)

```powershell
cd D:\your-project
Get-Content D:\yourpath\agent-workflow\rules\common\*.md | Set-Content AGENTS.md
```

## 说明

- Codex 读取项目根目录的 `AGENTS.md` 作为 agent 指令
- rules 内容（代码规范、测试、安全、git 工作流等）会注入到每次会话
- Skill 自动发现和 Session hooks 不支持
- 如需更新，重新运行上述命令覆盖 `AGENTS.md` 即可
