# Ralph Wiggum

> Autonomous AI coding with spec-driven development

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## What is Ralph Wiggum?

Ralph Wiggum is an approach to **fully autonomous AI-assisted software development** that combines:

- **Iterative self-correction** - AI agents work until acceptance criteria pass
- **Spec-driven development** - Professional-grade specifications guide the work
- **Cross-platform support** - Works with Claude Code, OpenAI Codex, and Cursor

## Quick Start

**Just tell your AI agent:**

> "Set up Ralph Wiggum in this project using the instructions at https://github.com/fstandhartinger/ralph-wiggum"

That's it. The AI will handle the rest.

---

## What Gets Installed

When you point your AI agent to this repo, it will:

1. **Create a project constitution** - Core principles and constraints
2. **Set up spec templates** - For creating feature specifications
3. **Install slash commands** - `/speckit.specify` and `/speckit.implement`
4. **Configure Ralph loops** - Autonomous implementation with completion signals

## How It Works

### 1. Specify Features
```
/speckit.specify Add user authentication with OAuth
```

### 2. Implement Autonomously
```
/speckit.implement
```

---

## AI Agent Setup Instructions

**If you are an AI agent reading this, follow these steps to set up Ralph Wiggum in the user's project:**

### Step 1: Create Directory Structure

```bash
mkdir -p .specify/memory
mkdir -p .specify/specs
mkdir -p templates
mkdir -p scripts
mkdir -p .cursor/commands
```

### Step 2: Copy Template Files

Copy all files from this repository's `templates/` folder to the user's project:

- `templates/constitution-template.md` -> `.specify/memory/constitution.md`
- `templates/spec-template.md` -> `templates/spec-template.md`
- `templates/checklist-template.md` -> `templates/checklist-template.md`

### Step 3: Copy Slash Commands

Copy the Cursor slash commands:
- `.cursor/commands/speckit.specify.md`
- `.cursor/commands/speckit.implement.md`

### Step 4: Copy Scripts

Copy and make executable:
```bash
cp scripts/ralph-loop.sh ./scripts/
cp scripts/setup-codex-prompts.sh ./scripts/
chmod +x scripts/*.sh
```

### Step 5: Customize the Constitution

Open `.specify/memory/constitution.md` and guide the user to fill in:
- `[PROJECT_NAME]` - Their project name
- `[PROJECT_DESCRIPTION]` - What the project does
- `[TECH_STACK]` - Technologies they're using
- Any other `[PLACEHOLDER]` sections

### Step 6: Create AGENTS.md

Create an `AGENTS.md` file in the project root with project-specific instructions for AI agents.

### Step 7: Verify Installation

Confirm these files exist:
- [ ] `.specify/memory/constitution.md`
- [ ] `templates/spec-template.md`
- [ ] `.cursor/commands/speckit.specify.md`
- [ ] `.cursor/commands/speckit.implement.md`
- [ ] `scripts/ralph-loop.sh`

### Step 8: Tell the User

Once setup is complete, inform the user:

> "Ralph Wiggum is now installed!
> 
> Use `/speckit.specify` to create your first feature specification.
> Use `/speckit.implement` to have me build it autonomously.
> 
> Your constitution is at `.specify/memory/constitution.md` - review and customize it for your project."

---

The AI agent will:
- Read the specification
- Implement iteratively until all acceptance criteria pass
- Commit and push changes
- Deploy and verify
- Output `<promise>DONE</promise>` when complete

## Supported Platforms

| Platform | Command |
|----------|---------|
| Claude Code | `/ralph-loop:ralph-loop "..."` |
| Codex CLI | `/prompts:ralph-all` |
| Cursor | `/speckit.implement` |

## Credits

This approach builds upon and is inspired by:

- [Original Ralph Wiggum technique](https://awesomeclaude.ai/ralph-wiggum) by the Claude community
- [How to Ralph Wiggum](https://github.com/ghuntley/how-to-ralph-wiggum) by Geoffrey Huntley
- [Claude Code Ralph Wiggum plugin](https://github.com/anthropics/claude-code/tree/main/plugins/ralph-wiggum)
- [SpecKit](https://github.com/github/spec-kit) by GitHub

Our contribution is integrating these approaches with a simplified SpecKit workflow optimized for modern AI agents.

## License

MIT License - See [LICENSE](LICENSE) for details.

---

**Website**: [ralph-wiggum.onrender.com](https://ralph-wiggum.onrender.com)
