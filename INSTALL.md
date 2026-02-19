# Installing Ralph Wiggum (Manual)

## The Easy Way (Recommended)

Just tell your AI assistant:

> "Set up Ralph Wiggum in this project using https://github.com/fstandhartinger/ralph-wiggum"

The AI will read [INSTALLATION.md](INSTALLATION.md) and guide you through an interactive setup.

---

## Manual Installation

If you prefer to install manually:

### 1. Create Directories

```bash
mkdir -p .specify/memory
mkdir -p specs
mkdir -p scripts
mkdir -p logs
mkdir -p history
mkdir -p .cursor/commands
```

### 2. Download Scripts

```bash
# Download ralph-loop.sh for Claude Code
curl -o scripts/ralph-loop.sh \
  https://raw.githubusercontent.com/fstandhartinger/ralph-wiggum/main/scripts/ralph-loop.sh

# Download ralph-loop-codex.sh for Codex
curl -o scripts/ralph-loop-codex.sh \
  https://raw.githubusercontent.com/fstandhartinger/ralph-wiggum/main/scripts/ralph-loop-codex.sh

# Make executable
chmod +x scripts/ralph-loop.sh scripts/ralph-loop-codex.sh
```

### 3. Create PROMPT Files

**PROMPT_build.md:**
```markdown
# Ralph Build Mode

Read `.specify/memory/constitution.md` first.

## Your Task

1. Look at `specs/` folder
2. Find the highest priority INCOMPLETE spec
3. Implement it completely
4. Run tests, verify acceptance criteria
5. Commit and push
6. Output `<promise>DONE</promise>` when done

Pick ONE spec per iteration. Do NOT output the magic phrase until truly complete.
```

**PROMPT_plan.md (optional):**
```markdown
# Ralph Planning Mode (Optional)

Read `.specify/memory/constitution.md` first.

## Your Task

1. Analyze all specs in `specs/`
2. Check what's implemented vs not
3. Create `IMPLEMENTATION_PLAN.md` with prioritized tasks
4. Output `<promise>DONE</promise>` when plan is complete
```

### 4. Create Constitution

Create `.specify/memory/constitution.md` with your project details:

```markdown
# [Your Project Name] Constitution

> [Brief project description]

## Version
1.0.0

---

## 🔍 Context Detection

### Context A: Ralph Loop (Implementation Mode)

You are in a Ralph loop if:
- Started by `ralph-loop.sh` or `ralph-loop-codex.sh`
- Prompt mentions "implement spec"

**In this mode:**
- Focus on implementation
- Pick highest priority incomplete spec
- Complete ALL acceptance criteria
- Output `<promise>DONE</promise>` when 100% complete

### Context B: Interactive Chat

When not in a Ralph loop:
- Be helpful and conversational
- Create specs with `/speckit.specify`

---

## Core Principles

### I. [Your Principle 1]
[Description]

### II. [Your Principle 2]
[Description]

### III. Simplicity & YAGNI
Build exactly what's needed, nothing more.

---

## Autonomy Configuration

### YOLO Mode: [ENABLED/DISABLED]
### Git Autonomy: [ENABLED/DISABLED]

---

## Ralph Loop Scripts

```bash
./scripts/ralph-loop.sh           # Build mode
./scripts/ralph-loop.sh 20        # Max 20 iterations
./scripts/ralph-loop-codex.sh     # Use Codex instead
```

---

## The Magic Word

When user says "Ralph, start working", provide the terminal command.

---

**Created:** [Date]
```

### 5. Create AGENTS.md

```markdown
# Agent Instructions

**Read the constitution:** `.specify/memory/constitution.md`

That file is your single source of truth for this project.
```

### 6. Create CLAUDE.md

Same content as AGENTS.md.

---

## You're Ready!

1. Create specs with `/speckit.specify [feature description]`
2. Run `./scripts/ralph-loop.sh` to start building

See the full [README](README.md) for detailed usage.

