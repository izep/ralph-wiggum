# AI AGENT: Execute These Instructions

> **YOU ARE AN AI CODING AGENT.** Follow these instructions to set up Ralph Wiggum in the user's project.
>
> **DO NOT just describe these steps.** Actually execute them using your file creation tools.

---

## Phase 1: Create Directory Structure

Create these directories in the user's project:

```bash
mkdir -p .specify/memory
mkdir -p .specify/specs
mkdir -p specs
mkdir -p scripts
mkdir -p logs
mkdir -p templates
mkdir -p .cursor/commands
mkdir -p .claude/commands
```

---

## Phase 2: Copy Core Files from Templates

Copy these files from this repository's `templates/` folder:

1. `templates/PROMPT_build.md` → `PROMPT_build.md`
2. `templates/PROMPT_plan.md` → `PROMPT_plan.md`
3. `templates/AGENTS.md` → `AGENTS.md`
4. `templates/spec-template.md` → `templates/spec-template.md`

Copy the loop scripts:

1. `scripts/ralph-loop.sh` → `scripts/ralph-loop.sh`
2. `scripts/ralph-loop-codex.sh` → `scripts/ralph-loop-codex.sh`

Make scripts executable:

```bash
chmod +x scripts/ralph-loop.sh scripts/ralph-loop-codex.sh
```

---

## Phase 3: Interview User & Create Constitution

**YOU MUST INTERVIEW THE USER** to gather the following information. Present questions one at a time and wait for responses.

### Question 1: Project Name
> "What is the name of your project?"

### Question 2: Project Description  
> "Please provide a brief description of your project (1-2 sentences)."

### Question 3: Core Principles
> "What are 2-3 core principles or values for your project? Examples: 'API-First', 'User-Centric Design', 'Performance Focus', 'Security First'"

### Question 4: Technical Stack
> "What is your project's primary technical stack? Examples: 'Next.js, TypeScript, Tailwind CSS' or 'Python, FastAPI, PostgreSQL'"

### Question 5: Source Code Location
> "Where is your main source code located? (e.g., 'src/', 'app/', 'lib/')"

### Question 6: Test Commands
> "What commands run your tests? (e.g., 'npm test', 'pytest', 'go test ./...')"

### Question 7: YOLO Mode (Full Autonomy)

Present this carefully:

> "Do you want your AI agent to operate in **YOLO Mode** (full autonomy)?
> 
> **What this means:**
> - Claude Code: Uses `--dangerously-skip-permissions`
> - Codex: Uses `--dangerously-bypass-approvals-and-sandbox`
> - Agent commits, pushes, and executes commands without asking
> 
> **⚠️ WARNING:** This bypasses all permission prompts. Only use in:
> - Isolated/sandboxed environments
> - Projects with good test coverage
> - When you trust the AI with full system access
> 
> **STRONGLY RECOMMENDED** for Ralph to work properly. Without YOLO mode, the loop will constantly pause for approvals.
> 
> Enable YOLO Mode? (yes/no)"

### Question 8: Git Autonomy

> "Do you want the AI to **autonomously commit and push** to your git repository without asking?
> 
> **RECOMMENDED:** Yes. This allows Ralph to make incremental progress and persist work between iterations.
> 
> Enable Git Autonomy? (yes/no)"

### Question 9: Work Item Source

> "Where will your specifications/work items come from?
> 
> **Options:**
> 1. **SpecKit Specs** (Recommended) - Markdown files in `specs/` folder created via `/speckit.specify`
> 2. **GitHub Issues** - Fetch issues from a GitHub repository
> 3. **Custom Source** - You'll provide a custom mechanism
> 
> Choose 1, 2, or 3:"

If they choose GitHub Issues, ask:
> "What is your GitHub repository URL? (e.g., https://github.com/username/repo)"

---

## Phase 4: Create Constitution

Create `.specify/memory/constitution.md` using the user's answers:

```markdown
# [PROJECT_NAME] Constitution

> [PROJECT_DESCRIPTION]

## Version
1.0.0

---

## Context Detection for AI Agents

This constitution is read by AI agents in two different contexts:

### 1. Interactive Mode
When the user is chatting with you outside of a Ralph loop:
- Be conversational and helpful
- Ask clarifying questions
- Guide the user through decisions
- Help create specifications via `/speckit.specify`

### 2. Ralph Loop Mode  
When you're running inside a Ralph bash loop:
- Be fully autonomous
- Pick the highest priority task from IMPLEMENTATION_PLAN.md
- Implement completely without asking
- Test thoroughly
- Commit and push (if Git Autonomy enabled)
- Output `<promise>DONE</promise>` ONLY when task is 100% complete

**How to detect your mode:** If you're being fed a prompt via stdin with instructions to pick a task from IMPLEMENTATION_PLAN.md, you're in Ralph Loop Mode.

---

## Core Principles

### I. [PRINCIPLE_1]
[Description]

### II. [PRINCIPLE_2]
[Description]

### III. Simplicity & YAGNI
Build exactly what's needed, nothing more. No premature abstractions.

---

## Technical Stack

| Layer | Technology |
|-------|------------|
| [Layer] | [Tech] |

---

## Project Structure

Source code: `[SOURCE_LOCATION]`

---

## Ralph Wiggum Configuration

### Autonomy Settings
- **YOLO Mode**: [ENABLED/DISABLED]
- **Git Autonomy**: [ENABLED/DISABLED]

### Work Item Source
- **Source**: [SpecKit Specs / GitHub Issues / Custom]
- **Location**: [specs/ folder / GitHub URL / Custom path]

### Ralph Loop Scripts
Located in `scripts/`:
- `ralph-loop.sh` - For Claude Code
- `ralph-loop-codex.sh` - For OpenAI Codex

**Usage:**
```bash
# Planning mode - creates IMPLEMENTATION_PLAN.md from specs
./scripts/ralph-loop.sh plan

# Build mode - implements tasks one by one
./scripts/ralph-loop.sh

# With max iterations
./scripts/ralph-loop.sh 20
```

---

## Development Workflow

### Creating Specifications (SpecKit approach)
Use `/speckit.specify` to create feature specifications:
1. Describe the feature in natural language
2. Agent generates professional spec with acceptance criteria
3. Spec saved to `specs/NNN-feature-name/spec.md`

### Running Ralph Loop
1. Run `./scripts/ralph-loop.sh plan` to create task list
2. Run `./scripts/ralph-loop.sh` to start building
3. Each iteration picks ONE task and completes it
4. Loop continues until all tasks done or max iterations

### Completion Signal
- Per-task: `<promise>DONE</promise>` when acceptance criteria pass
- Agent MUST verify all criteria before outputting this signal

---

## Validation Commands

```bash
[TEST_COMMANDS]
```

---

## Governance

- **Amendments**: Update this file, increment version
- **Compliance**: Follow principles in spirit, not just letter

---

**Created**: [DATE]
```

---

## Phase 5: Create AGENTS.md and CLAUDE.md

Create `AGENTS.md`:

```markdown
# Agent Instructions

**Read the constitution**: `.specify/memory/constitution.md`

That file is your single source of truth for working on this project.
```

Create `CLAUDE.md` (same content):

```markdown
# Claude Code Instructions

**Read the constitution**: `.specify/memory/constitution.md`

That file is your single source of truth for working on this project.
```

---

## Phase 6: Set Up Cursor Commands (Optional)

If using Cursor, create `.cursor/commands/speckit.specify.md`:

```markdown
---
description: Create a feature specification from natural language
---

Create a professional specification for this feature:

$ARGUMENTS

## Process

1. Generate a short name for the spec folder (2-4 words)
2. Find next spec number: `ls -d specs/[0-9]*/ 2>/dev/null | sort -t/ -k2 -n`
3. Create `specs/NNN-short-name/spec.md` using the spec template
4. Include a **Completion Signal** section with:
   - Implementation checklist
   - Testing requirements  
   - Acceptance criteria
   - `**Output when ALL checks pass**: \`<promise>DONE</promise>\``

## Guidelines

- Focus on WHAT users need, not HOW to implement
- Make requirements testable and unambiguous
- Include clear acceptance criteria
```

---

## Phase 7: Explain Next Steps to User

Tell the user:

---

### ✅ Ralph Wiggum is Ready!

Your project is now set up with the Ralph Wiggum + SpecKit approach.

**Files created:**
- `.specify/memory/constitution.md` — Your project's source of truth
- `PROMPT_build.md` & `PROMPT_plan.md` — Ralph loop prompts
- `IMPLEMENTATION_PLAN.md` — Shared state between loops
- `scripts/ralph-loop.sh` — Claude Code loop
- `scripts/ralph-loop-codex.sh` — Codex loop

---

### Your Workflow

**Step 1: Create Specifications**

Use `/speckit.specify` (in Cursor) or describe features to me:
```
/speckit.specify Add user authentication with OAuth
```

I'll create a professional spec with acceptance criteria.

**Step 2: Run Planning Mode**

When you have specs ready:
```bash
./scripts/ralph-loop.sh plan
```

This creates a prioritized task list in IMPLEMENTATION_PLAN.md.

**Step 3: The Magic Word**

When you're ready for Ralph to start building, just say:

> **"Start Ralph"** or **"Let Ralph work"**

I'll tell you the exact command to run in your terminal.

---

### How the Loop Works

```
Loop 1: Read plan → Pick task A → Implement → Test → Commit → <DONE>
Loop 2: Read plan → Pick task B → Implement → Test → Commit → <DONE>
Loop 3: Read plan → Pick task C → Implement → Test → Commit → <DONE>
...
```

Each iteration gets fresh context. The plan on disk is the shared state.

---

### Quick Reference

| Action | Command |
|--------|---------|
| Create spec | `/speckit.specify [description]` |
| Create task list | `./scripts/ralph-loop.sh plan` |
| Start building | `./scripts/ralph-loop.sh` |
| Max 20 iterations | `./scripts/ralph-loop.sh 20` |
| Use Codex instead | `./scripts/ralph-loop-codex.sh` |

---

Ready to create your first specification?
