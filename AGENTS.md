# Agent Instructions: Ralph Wiggum Setup

> Instructions for AI coding agents to install Ralph Wiggum in a project

## Your Task

You are setting up the Ralph Wiggum autonomous development system in a user's project.

## Installation Steps

### Step 1: Create Directory Structure

```bash
mkdir -p .specify/memory
mkdir -p .specify/specs
mkdir -p templates
mkdir -p scripts
mkdir -p .cursor/commands
```

### Step 2: Create Constitution

Create `.specify/memory/constitution.md` with core project principles:

```markdown
# Project Constitution

## Version
1.0.0

## Core Principles

1. **Simplicity** - Avoid over-engineering (YAGNI)
2. **Quality** - Test everything before marking complete
3. **Autonomy** - Work fully autonomously, commit and push without asking
4. **Iteration** - If something fails, fix it and retry

## Agent Workflow (YOLO Mode)

You are expected to work **fully autonomously**:

1. Read spec and plan thoroughly
2. Implement incrementally, testing each step
3. Commit and push autonomously
4. Use browser tools to verify UI works
5. Deploy and test the deployed version
6. Iterate until all acceptance criteria pass

## Completion Signal

Every spec must have a Completion Signal section. Output `<promise>DONE</promise>` when complete.
```

### Step 3: Create Spec Template

Create `templates/spec-template.md` (copy from this repo's templates folder).

### Step 4: Create Slash Commands

Create `.cursor/commands/speckit.specify.md` and `.cursor/commands/speckit.implement.md` (copy from this repo).

### Step 5: Create Ralph Loop Scripts

Create `scripts/ralph-loop.sh` (copy from this repo).

### Step 6: Update .gitignore

Add any necessary ignores for the project type.

### Step 7: Create Initial AGENTS.md

Create an `AGENTS.md` file with project-specific instructions.

## Verification

After setup, verify:
- [ ] `.specify/memory/constitution.md` exists
- [ ] `templates/spec-template.md` exists
- [ ] `.cursor/commands/` contains slash commands
- [ ] `scripts/ralph-loop.sh` is executable

## Post-Setup

Tell the user:
"Ralph Wiggum is now installed! Use `/speckit.specify` to create your first feature specification, then `/speckit.implement` to have me build it autonomously."
