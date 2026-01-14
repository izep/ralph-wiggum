# CLAUDE.md - Claude Code Specific Instructions

> Claude-specific additions to `AGENTS.md`. Read `AGENTS.md` first for universal instructions.

## Claude Code Setup

Claude Code automatically reads this file AND `AGENTS.md`. The shared instructions
(project context, design system, APIs, workflow) should live in `AGENTS.md`.

## Claude-Specific Ralph Wiggum Loop

Use this format for the Ralph loop command:

```
/ralph-loop:ralph-loop "Implement spec {name} from specs/{name}/spec.md.
Complete ALL Completion Signal requirements.
Output <promise>DONE</promise> when complete." --completion-promise "DONE" --max-iterations 30
```

### Implementation Flow (Claude)

1. **Read** - Spec + Completion Signal requirements
2. **Implement** - Build features incrementally
3. **Test** - Unit -> Integration -> Browser -> Visual -> Console
4. **Commit & Push** - Autonomously, without waiting for user
5. **Deploy** - If the project requires deployment, do so and verify
6. **Iterate** - If ANY check fails, fix and repeat
7. **Complete** - Output `<promise>DONE</promise>`
8. **Document** - Update project history if required

Make decisions. Solve problems. **Don't wait for approval on implementation details.**
Commit and push autonomously. Only ask when genuinely stuck.

## Claude-Specific MCP Usage

If MCP tools are available in your environment:

- **Browser MCP**: Use browser automation to verify UI flows
- **Hosting MCP**: Use provider tools to deploy and watch logs
- **Database MCP**: Use for schema or data work if needed

## Changelog

- 2026-01-14: Genericized instructions for the Ralph Wiggum toolkit
