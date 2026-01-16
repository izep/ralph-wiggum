#!/bin/bash
#
# Ralph Loop for Claude Code
#
# Based on Geoffrey Huntley's Ralph Wiggum methodology:
# https://github.com/ghuntley/how-to-ralph-wiggum
#
# Combined with SpecKit-style specifications.
#
# Key principles:
# - Each iteration picks ONE task/spec to work on
# - Agent works until acceptance criteria are met
# - Only outputs <promise>DONE</promise> when truly complete
# - Bash loop checks for magic phrase before continuing
# - Fresh context window each iteration
#
# Work sources (in priority order):
# 1. IMPLEMENTATION_PLAN.md (if exists) - pick highest priority task
# 2. specs/ folder - pick highest priority incomplete spec
#
# Usage:
#   ./scripts/ralph-loop.sh              # Build mode (unlimited)
#   ./scripts/ralph-loop.sh 20           # Build mode (max 20 iterations)
#   ./scripts/ralph-loop.sh plan         # Planning mode (creates IMPLEMENTATION_PLAN.md)
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOG_DIR="$PROJECT_DIR/logs"
CONSTITUTION="$PROJECT_DIR/.specify/memory/constitution.md"

# Configuration
MAX_ITERATIONS=0  # 0 = unlimited
MODE="build"
CLAUDE_CMD="claude"
YOLO_FLAG="--dangerously-skip-permissions"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

mkdir -p "$LOG_DIR"

# Check constitution for YOLO setting
YOLO_ENABLED=true
if [[ -f "$CONSTITUTION" ]]; then
    if grep -q "YOLO Mode.*DISABLED" "$CONSTITUTION" 2>/dev/null; then
        YOLO_ENABLED=false
    fi
fi

show_help() {
    cat <<EOF
Ralph Loop for Claude Code

Based on Geoffrey Huntley's Ralph Wiggum methodology + SpecKit specs.
https://github.com/ghuntley/how-to-ralph-wiggum

Usage:
  ./scripts/ralph-loop.sh              # Build mode, unlimited iterations
  ./scripts/ralph-loop.sh 20           # Build mode, max 20 iterations  
  ./scripts/ralph-loop.sh plan         # Planning mode (optional)

Modes:
  build (default)  Pick spec/task and implement
  plan             Create IMPLEMENTATION_PLAN.md from specs (OPTIONAL)

Work Sources (checked in order):
  1. IMPLEMENTATION_PLAN.md - If exists, pick highest priority task
  2. specs/ folder - Otherwise, pick highest priority incomplete spec

The plan mode is OPTIONAL. Most projects can work directly from specs.

How it works:
  1. Each iteration feeds PROMPT.md to Claude via stdin
  2. Claude picks the HIGHEST PRIORITY incomplete spec/task
  3. Claude implements, tests, and verifies acceptance criteria
  4. Claude outputs <promise>DONE</promise> ONLY if criteria are met
  5. Bash loop checks for the magic phrase
  6. If found, loop continues to next iteration (fresh context)
  7. If not found, loop retries

EOF
}

# Parse arguments
if [ "$1" = "plan" ]; then
    MODE="plan"
    MAX_ITERATIONS=${2:-1}  # Default to 1 iteration for planning
elif [[ "$1" =~ ^[0-9]+$ ]]; then
    MODE="build"
    MAX_ITERATIONS=$1
elif [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    show_help
    exit 0
fi

cd "$PROJECT_DIR"

# Check if Claude CLI is available
if ! command -v "$CLAUDE_CMD" &> /dev/null; then
    echo -e "${RED}Error: Claude CLI not found${NC}"
    echo ""
    echo "Install Claude Code CLI and authenticate first."
    echo "https://claude.ai/code"
    exit 1
fi

# Determine which prompt to use based on mode and available files
if [ "$MODE" = "plan" ]; then
    PROMPT_FILE="PROMPT_plan.md"
else
    PROMPT_FILE="PROMPT_build.md"
fi

# Create/update the build prompt to be flexible about plan vs specs
cat > "PROMPT_build.md" << 'BUILDEOF'
# Ralph Build Mode

Based on Geoffrey Huntley's Ralph Wiggum methodology.

---

## Phase 0: Orient

0a. Read `.specify/memory/constitution.md` for project principles.

0b. Study `specs/` to understand feature specifications.

0c. Check if `IMPLEMENTATION_PLAN.md` exists.

---

## Phase 1: Select Work Item

### If IMPLEMENTATION_PLAN.md exists:
Pick the **HIGHEST PRIORITY** incomplete task from the plan.

### If NO plan exists (preferred simple approach):
Look at `specs/` folder and pick the **HIGHEST PRIORITY** spec that:
- Is NOT marked as complete (no `[x] DONE` or similar in the spec)
- Has incomplete acceptance criteria
- Has the highest priority (lower number = higher priority, e.g., 001 before 010)

Before implementing, search the codebase — don't assume it's not done.

---

## Phase 2: Implement

Implement the selected spec/task completely:
- Follow the spec's requirements exactly
- Write clean, maintainable code
- Add tests as needed
- Mark the spec as complete when done

---

## Phase 3: Validate

Run the project's test suite and verify:
- All tests pass
- No lint errors
- The spec's acceptance criteria are 100% met

---

## Phase 4: Commit & Update

1. If using IMPLEMENTATION_PLAN.md, update it to mark task complete
2. If working directly from specs, add `## Status: COMPLETE` to the spec file
3. `git add -A`
4. `git commit` with a descriptive message
5. `git push`

---

## Completion Signal

**CRITICAL:** Only output the magic phrase when the spec/task is 100% complete.

Check:
- [ ] Implementation matches all requirements
- [ ] All tests pass
- [ ] All acceptance criteria verified
- [ ] Changes committed and pushed
- [ ] Spec marked as complete

**If ALL checks pass, output:** `<promise>DONE</promise>`

**If ANY check fails:** Fix the issue and try again. Do NOT output the magic phrase.
BUILDEOF

# Create planning prompt (only used if plan mode is explicitly requested)
cat > "PROMPT_plan.md" << 'PLANEOF'
# Ralph Planning Mode (OPTIONAL)

This mode is OPTIONAL. Most projects work fine directly from specs.

Only use this when you want a detailed breakdown of specs into smaller tasks.

---

## Phase 0: Orient

0a. Read `.specify/memory/constitution.md` for project principles.

0b. Study `specs/` to learn all feature specifications.

---

## Phase 1: Gap Analysis

Compare specs against current codebase:
- What's fully implemented?
- What's partially done?
- What's not started?
- What has issues or bugs?

---

## Phase 2: Create Plan

Create `IMPLEMENTATION_PLAN.md` with a prioritized task list:

```markdown
# Implementation Plan

> Auto-generated breakdown of specs into tasks.
> Delete this file to return to working directly from specs.

## Priority Tasks

- [ ] [HIGH] Task description - from spec NNN
- [ ] [HIGH] Task description - from spec NNN  
- [ ] [MEDIUM] Task description
- [ ] [LOW] Task description

## Completed

- [x] Completed task
```

Prioritize by:
1. Dependencies (do prerequisites first)
2. Impact (high-value features first)
3. Complexity (mix easy wins with harder tasks)

---

## Completion Signal

When the plan is complete and saved:

`<promise>DONE</promise>`
PLANEOF

# Check prompt file exists
if [ ! -f "$PROMPT_FILE" ]; then
    echo -e "${RED}Error: $PROMPT_FILE not found${NC}"
    exit 1
fi

# Build Claude flags
CLAUDE_FLAGS="-p"
if [ "$YOLO_ENABLED" = true ]; then
    CLAUDE_FLAGS="$CLAUDE_FLAGS $YOLO_FLAG"
fi

# Get current branch
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "main")

# Check for work sources - count .md files in specs/
HAS_PLAN=false
HAS_SPECS=false
SPEC_COUNT=0
[ -f "IMPLEMENTATION_PLAN.md" ] && HAS_PLAN=true
if [ -d "specs" ]; then
    SPEC_COUNT=$(find specs -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l)
    [ "$SPEC_COUNT" -gt 0 ] && HAS_SPECS=true
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}              RALPH LOOP (Claude Code) STARTING              ${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}Mode:${NC}     $MODE"
echo -e "${BLUE}Prompt:${NC}   $PROMPT_FILE"
echo -e "${BLUE}Branch:${NC}   $CURRENT_BRANCH"
echo -e "${YELLOW}YOLO:${NC}     $([ "$YOLO_ENABLED" = true ] && echo "ENABLED" || echo "DISABLED")"
[ $MAX_ITERATIONS -gt 0 ] && echo -e "${BLUE}Max:${NC}      $MAX_ITERATIONS iterations"
echo ""
echo -e "${BLUE}Work source:${NC}"
if [ "$HAS_PLAN" = true ]; then
    echo -e "  ${GREEN}✓${NC} IMPLEMENTATION_PLAN.md (will use this)"
else
    echo -e "  ${YELLOW}○${NC} IMPLEMENTATION_PLAN.md (not found, that's OK)"
fi
if [ "$HAS_SPECS" = true ]; then
    echo -e "  ${GREEN}✓${NC} specs/ folder ($SPEC_COUNT specs)"
else
    echo -e "  ${RED}✗${NC} specs/ folder (no .md files found)"
fi
echo ""
echo -e "${CYAN}The loop checks for <promise>DONE</promise> in each iteration.${NC}"
echo -e "${CYAN}Agent must verify acceptance criteria before outputting it.${NC}"
echo ""
echo -e "${YELLOW}Press Ctrl+C to stop the loop${NC}"
echo ""

ITERATION=0
CONSECUTIVE_FAILURES=0
MAX_CONSECUTIVE_FAILURES=3

while true; do
    # Check max iterations
    if [ $MAX_ITERATIONS -gt 0 ] && [ $ITERATION -ge $MAX_ITERATIONS ]; then
        echo -e "${GREEN}Reached max iterations: $MAX_ITERATIONS${NC}"
        break
    fi

    ITERATION=$((ITERATION + 1))
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

    echo ""
    echo -e "${PURPLE}════════════════════ LOOP $ITERATION ════════════════════${NC}"
    echo -e "${BLUE}[$TIMESTAMP]${NC} Starting iteration $ITERATION"
    echo ""

    # Log file for this iteration
    LOG_FILE="$LOG_DIR/ralph_${MODE}_$(date '+%Y%m%d_%H%M%S').log"

    # Run Claude with prompt via stdin, capture output
    CLAUDE_OUTPUT=""
    if CLAUDE_OUTPUT=$(cat "$PROMPT_FILE" | "$CLAUDE_CMD" $CLAUDE_FLAGS 2>&1 | tee "$LOG_FILE"); then
        echo ""
        echo -e "${GREEN}✓ Claude execution completed${NC}"
        
        # Check if DONE promise was output
        if echo "$CLAUDE_OUTPUT" | grep -q "<promise>DONE</promise>"; then
            echo -e "${GREEN}✓ Completion signal detected: <promise>DONE</promise>${NC}"
            echo -e "${GREEN}✓ Task completed successfully!${NC}"
            CONSECUTIVE_FAILURES=0
            
            # For planning mode, stop after one successful plan
            if [ "$MODE" = "plan" ]; then
                echo ""
                echo -e "${GREEN}Planning complete!${NC}"
                echo -e "${CYAN}Run './scripts/ralph-loop.sh' to start building.${NC}"
                echo -e "${CYAN}Or delete IMPLEMENTATION_PLAN.md to work directly from specs.${NC}"
                break
            fi
        else
            echo -e "${YELLOW}⚠ No completion signal found${NC}"
            echo -e "${YELLOW}  Agent did not output <promise>DONE</promise>${NC}"
            echo -e "${YELLOW}  This means acceptance criteria were not met.${NC}"
            echo -e "${YELLOW}  Retrying in next iteration...${NC}"
            CONSECUTIVE_FAILURES=$((CONSECUTIVE_FAILURES + 1))
            
            if [ $CONSECUTIVE_FAILURES -ge $MAX_CONSECUTIVE_FAILURES ]; then
                echo ""
                echo -e "${RED}⚠ $MAX_CONSECUTIVE_FAILURES consecutive iterations without completion.${NC}"
                echo -e "${RED}  The agent may be stuck. Consider:${NC}"
                echo -e "${RED}  - Checking the logs in $LOG_DIR${NC}"
                echo -e "${RED}  - Simplifying the current spec${NC}"
                echo -e "${RED}  - Manually fixing blocking issues${NC}"
                echo ""
                CONSECUTIVE_FAILURES=0
            fi
        fi
    else
        echo -e "${RED}✗ Claude execution failed${NC}"
        echo -e "${YELLOW}Check log: $LOG_FILE${NC}"
        CONSECUTIVE_FAILURES=$((CONSECUTIVE_FAILURES + 1))
    fi

    # Push changes after each iteration (if any)
    git push origin "$CURRENT_BRANCH" 2>/dev/null || {
        if git log origin/$CURRENT_BRANCH..HEAD --oneline 2>/dev/null | grep -q .; then
            echo -e "${YELLOW}Push failed, creating remote branch...${NC}"
            git push -u origin "$CURRENT_BRANCH" 2>/dev/null || true
        fi
    }

    # Brief pause between iterations
    echo ""
    echo -e "${BLUE}Waiting 2s before next iteration...${NC}"
    sleep 2
done

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}         RALPH LOOP FINISHED ($ITERATION iterations)         ${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
