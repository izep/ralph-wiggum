#!/bin/bash
#
# Ralph Wiggum Loop Runner
# Universal script for running Ralph loops with Claude Code or OpenAI Codex CLI
#
# Usage:
#   ./scripts/ralph-loop.sh <spec-name>        # Run single spec
#   ./scripts/ralph-loop.sh --all              # Run all specs
#   ./scripts/ralph-loop.sh --all --headless   # Run all specs non-interactively
#
# Examples:
#   ./scripts/ralph-loop.sh 001-project-setup
#   ./scripts/ralph-loop.sh --all
#   ./scripts/ralph-loop.sh 005-feature-name --codex
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Defaults
USE_CODEX=false
HEADLESS=false
ALL_SPECS=false
SPEC_NAME=""
MAX_ITERATIONS=30

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --all)
            ALL_SPECS=true
            shift
            ;;
        --headless)
            HEADLESS=true
            shift
            ;;
        --codex)
            USE_CODEX=true
            shift
            ;;
        --claude)
            USE_CODEX=false
            shift
            ;;
        --max-iterations)
            MAX_ITERATIONS="$2"
            shift 2
            ;;
        --help|-h)
            echo "Ralph Wiggum Loop Runner"
            echo ""
            echo "Usage:"
            echo "  ./scripts/ralph-loop.sh <spec-name>        # Run single spec"
            echo "  ./scripts/ralph-loop.sh --all              # Run all specs"
            echo "  ./scripts/ralph-loop.sh --all --headless   # Run all specs non-interactively"
            echo ""
            echo "Options:"
            echo "  --all             Process all specs in order"
            echo "  --headless        Run non-interactively (requires --codex)"
            echo "  --codex           Use OpenAI Codex CLI"
            echo "  --claude          Use Claude Code (default)"
            echo "  --max-iterations  Maximum iterations per spec (default: 30)"
            echo "  --help, -h        Show this help message"
            exit 0
            ;;
        *)
            SPEC_NAME="$1"
            shift
            ;;
    esac
done

# Validate
if [[ "$ALL_SPECS" == "false" && -z "$SPEC_NAME" ]]; then
    echo -e "${RED}Error: Please specify a spec name or use --all${NC}"
    echo "Usage: ./scripts/ralph-loop.sh <spec-name> or ./scripts/ralph-loop.sh --all"
    exit 1
fi

cd "$PROJECT_DIR"

# Detect available CLI
detect_cli() {
    if command -v codex &> /dev/null && [[ "$USE_CODEX" == "true" ]]; then
        echo "codex"
    elif command -v claude &> /dev/null; then
        echo "claude"
    elif command -v codex &> /dev/null; then
        echo "codex"
    else
        echo "none"
    fi
}

CLI=$(detect_cli)

if [[ "$CLI" == "none" ]]; then
    echo -e "${RED}Error: Neither 'claude' nor 'codex' CLI found in PATH${NC}"
    echo "Please install one of:"
    echo "  - Claude Code: https://claude.ai/code"
    echo "  - OpenAI Codex: https://github.com/openai/codex"
    exit 1
fi

echo -e "${BLUE}Using CLI: $CLI${NC}"

# Build the prompt for a single spec
build_spec_prompt() {
    local spec="$1"
    cat <<EOF
Implement the spec '$spec' from specs/$spec/spec.md.

BEFORE YOU START, read these files:
1. RALPH_PROMPT.md - Master instructions
2. .specify/memory/constitution.md - Core principles
3. AGENTS.md - Development guidelines

PROCESS:
1. Read the spec file thoroughly
2. Implement the feature following acceptance criteria
3. Run tests as required by the Completion Signal
4. Use browser automation to verify UI if applicable
5. Commit and push with meaningful messages
6. Update project history if required

AUTONOMY: You have FULL autonomy. Commit, push, deploy without asking.

OUTPUT when complete: <promise>DONE</promise>
EOF
}

# Build the prompt for all specs
build_all_specs_prompt() {
    cat <<EOF
Implement ALL specifications in the specs/ folder, one by one, in numerical order.

BEFORE YOU START, read these files:
1. RALPH_PROMPT.md - Master instructions
2. .specify/memory/constitution.md - Core principles
3. AGENTS.md - Development guidelines
4. history.md - See what's been done already (if present)

PROCESS for each spec:
1. Read the spec file: specs/{spec-name}/spec.md
2. Implement the feature following acceptance criteria
3. Run tests as required by the Completion Signal
4. Use browser automation to verify UI if applicable
5. Commit and push with meaningful messages
6. Update project history if required
7. Move to the next spec

AUTONOMY: You have FULL autonomy. Commit, push, deploy without asking.

OUTPUT when ALL specs are complete: <promise>ALL_DONE</promise>
EOF
}

# Run with Claude Code
run_claude() {
    local prompt="$1"

    if [[ "$HEADLESS" == "true" ]]; then
        echo -e "${YELLOW}Note: Claude Code doesn't support headless mode. Running interactively.${NC}"
    fi

    echo -e "${GREEN}Starting Claude Code with Ralph loop...${NC}"
    echo ""
    echo "Paste this command in Claude Code:"
    echo ""
    echo -e "${BLUE}/ralph-loop:ralph-loop \"$prompt\" --completion-promise \"DONE\" --max-iterations $MAX_ITERATIONS${NC}"
    echo ""

    if command -v claude &> /dev/null; then
        claude "$prompt"
    else
        echo -e "${YELLOW}Claude CLI not found. Please manually start Claude Code and paste the command above.${NC}"
    fi
}

# Run with OpenAI Codex CLI
run_codex() {
    local prompt="$1"

    if [[ "$HEADLESS" == "true" ]]; then
        echo -e "${GREEN}Starting Codex in headless mode...${NC}"
        codex --full-auto --quiet "$prompt"
    else
        echo -e "${GREEN}Starting Codex interactively...${NC}"
        codex "$prompt"
    fi
}

# Main execution
if [[ "$ALL_SPECS" == "true" ]]; then
    PROMPT=$(build_all_specs_prompt)
    echo -e "${GREEN}Running Ralph loop for ALL specs...${NC}"
else
    if [[ ! -d "specs/$SPEC_NAME" ]]; then
        echo -e "${RED}Error: Spec '$SPEC_NAME' not found in specs/ folder${NC}"
        echo "Available specs:"
        ls -1 specs/
        exit 1
    fi

    PROMPT=$(build_spec_prompt "$SPEC_NAME")
    echo -e "${GREEN}Running Ralph loop for spec: $SPEC_NAME${NC}"
fi

echo -e "${BLUE}Max iterations: $MAX_ITERATIONS${NC}"
echo ""

if [[ "$CLI" == "codex" || "$USE_CODEX" == "true" ]]; then
    run_codex "$PROMPT"
else
    run_claude "$PROMPT"
fi

echo ""
echo -e "${GREEN}Ralph loop completed!${NC}"
