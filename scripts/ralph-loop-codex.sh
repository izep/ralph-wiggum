#!/bin/bash
#
# Ralph Loop for OpenAI Codex CLI
#
# Based on Geoffrey Huntley's Ralph Wiggum methodology.
# Combined with SpecKit-style specifications.
#
# Usage:
#   ./scripts/ralph-loop-codex.sh              # Build mode (unlimited)
#   ./scripts/ralph-loop-codex.sh 20           # Build mode (max 20 iterations)
#   ./scripts/ralph-loop-codex.sh plan         # Planning mode (optional)
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOG_DIR="$PROJECT_DIR/logs"
CONSTITUTION="$PROJECT_DIR/.specify/memory/constitution.md"

# Configuration
MAX_ITERATIONS=0  # 0 = unlimited
MODE="build"

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
Ralph Loop for OpenAI Codex CLI

Usage:
  ./scripts/ralph-loop-codex.sh              # Build mode, unlimited
  ./scripts/ralph-loop-codex.sh 20           # Build mode, max 20 iterations
  ./scripts/ralph-loop-codex.sh plan         # Planning mode (OPTIONAL)

Modes:
  build (default)  Pick incomplete spec and implement
  plan             Create IMPLEMENTATION_PLAN.md (OPTIONAL)

Work Source:
  Agent reads specs/*.md and picks the highest priority incomplete spec.

YOLO Mode: Uses --dangerously-bypass-approvals-and-sandbox

EOF
}

# Parse arguments
if [ "$1" = "plan" ]; then
    MODE="plan"
    MAX_ITERATIONS=${2:-1}
elif [[ "$1" =~ ^[0-9]+$ ]]; then
    MODE="build"
    MAX_ITERATIONS=$1
elif [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    show_help
    exit 0
fi

cd "$PROJECT_DIR"

# Check if Codex CLI is available
if ! command -v codex &> /dev/null; then
    echo -e "${RED}Error: Codex CLI not found${NC}"
    echo ""
    echo "Install Codex CLI:"
    echo "  npm install -g @openai/codex"
    echo ""
    echo "Then authenticate:"
    echo "  codex login"
    exit 1
fi

# Determine prompt file
if [ "$MODE" = "plan" ]; then
    PROMPT_FILE="PROMPT_plan.md"
else
    PROMPT_FILE="PROMPT_build.md"
fi

# Check prompt file exists
if [ ! -f "$PROMPT_FILE" ]; then
    echo -e "${RED}Error: $PROMPT_FILE not found${NC}"
    echo "Create the prompt file or run ./scripts/ralph-loop.sh first."
    exit 1
fi

# Build Codex flags for exec mode
CODEX_FLAGS="exec"
if [ "$YOLO_ENABLED" = true ]; then
    CODEX_FLAGS="$CODEX_FLAGS --dangerously-bypass-approvals-and-sandbox"
fi

# Get current branch
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "main")

# Check for work sources - count .md files in specs/
HAS_SPECS=false
SPEC_COUNT=0
if [ -d "specs" ]; then
    SPEC_COUNT=$(find specs -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l)
    [ "$SPEC_COUNT" -gt 0 ] && HAS_SPECS=true
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}              RALPH LOOP (Codex) STARTING                    ${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}Mode:${NC}     $MODE"
echo -e "${BLUE}Prompt:${NC}   $PROMPT_FILE"
echo -e "${BLUE}Branch:${NC}   $CURRENT_BRANCH"
echo -e "${YELLOW}YOLO:${NC}     $([ "$YOLO_ENABLED" = true ] && echo "ENABLED" || echo "DISABLED")"
[ $MAX_ITERATIONS -gt 0 ] && echo -e "${BLUE}Max:${NC}      $MAX_ITERATIONS iterations"
echo ""
echo -e "${BLUE}Work source:${NC}"
if [ "$HAS_SPECS" = true ]; then
    echo -e "  ${GREEN}✓${NC} specs/ folder ($SPEC_COUNT specs)"
else
    echo -e "  ${RED}✗${NC} specs/ folder (no .md files found)"
fi
echo ""
echo -e "${CYAN}Using: codex $CODEX_FLAGS${NC}"
echo -e "${CYAN}Agent must output <promise>DONE</promise> when complete.${NC}"
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
    LOG_FILE="$LOG_DIR/ralph_codex_${MODE}_$(date '+%Y%m%d_%H%M%S').log"
    OUTPUT_FILE="$LOG_DIR/ralph_codex_output_$(date '+%Y%m%d_%H%M%S').txt"

    # Run Codex with exec mode, reading prompt from stdin with "-"
    # Use --output-last-message to capture the final response for checking
    echo -e "${BLUE}Running: cat $PROMPT_FILE | codex $CODEX_FLAGS - --output-last-message $OUTPUT_FILE${NC}"
    echo ""
    
    CODEX_EXIT=0
    if cat "$PROMPT_FILE" | codex $CODEX_FLAGS - --output-last-message "$OUTPUT_FILE" 2>&1 | tee "$LOG_FILE"; then
        echo ""
        echo -e "${GREEN}✓ Codex execution completed${NC}"
        
        # Check if DONE promise was output (in the last message file)
        if [ -f "$OUTPUT_FILE" ] && grep -q "<promise>DONE</promise>" "$OUTPUT_FILE"; then
            echo -e "${GREEN}✓ Completion signal detected: <promise>DONE</promise>${NC}"
            echo -e "${GREEN}✓ Task completed successfully!${NC}"
            CONSECUTIVE_FAILURES=0
            
            if [ "$MODE" = "plan" ]; then
                echo ""
                echo -e "${GREEN}Planning complete!${NC}"
                break
            fi
        # Also check the main log
        elif grep -q "<promise>DONE</promise>" "$LOG_FILE"; then
            echo -e "${GREEN}✓ Completion signal detected in output${NC}"
            echo -e "${GREEN}✓ Task completed successfully!${NC}"
            CONSECUTIVE_FAILURES=0
        else
            echo -e "${YELLOW}⚠ No completion signal found${NC}"
            echo -e "${YELLOW}  Agent did not output <promise>DONE</promise>${NC}"
            echo -e "${YELLOW}  Retrying in next iteration...${NC}"
            CONSECUTIVE_FAILURES=$((CONSECUTIVE_FAILURES + 1))
            
            if [ $CONSECUTIVE_FAILURES -ge $MAX_CONSECUTIVE_FAILURES ]; then
                echo ""
                echo -e "${RED}⚠ $MAX_CONSECUTIVE_FAILURES consecutive iterations without completion.${NC}"
                echo -e "${RED}  The agent may be stuck. Check logs:${NC}"
                echo -e "${RED}  - $LOG_FILE${NC}"
                echo -e "${RED}  - $OUTPUT_FILE${NC}"
                CONSECUTIVE_FAILURES=0
            fi
        fi
    else
        CODEX_EXIT=$?
        echo -e "${RED}✗ Codex execution failed (exit code: $CODEX_EXIT)${NC}"
        echo -e "${YELLOW}Check log: $LOG_FILE${NC}"
        CONSECUTIVE_FAILURES=$((CONSECUTIVE_FAILURES + 1))
    fi

    # Push changes after each iteration
    git push origin "$CURRENT_BRANCH" 2>/dev/null || {
        if git log origin/$CURRENT_BRANCH..HEAD --oneline 2>/dev/null | grep -q .; then
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
echo -e "${GREEN}       RALPH LOOP (Codex) FINISHED ($ITERATION iterations)   ${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
