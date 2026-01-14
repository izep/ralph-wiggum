#!/bin/bash
#
# Setup Codex CLI prompts for Ralph Wiggum loop
#
# This script copies the Ralph loop prompts to ~/.codex/prompts/
# so they can be invoked as slash commands in Codex CLI.
#
# Usage:
#   ./scripts/setup-codex-prompts.sh
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CODEX_PROMPTS_DIR="$HOME/.codex/prompts"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}Setting up Codex CLI prompts for Ralph Wiggum loop...${NC}"
echo ""

# Create prompts directory if it doesn't exist
if [[ ! -d "$CODEX_PROMPTS_DIR" ]]; then
    echo -e "${YELLOW}Creating $CODEX_PROMPTS_DIR...${NC}"
    mkdir -p "$CODEX_PROMPTS_DIR"
fi

# Copy prompt files
echo "Copying prompt files..."
cp "$PROJECT_DIR/codex-prompts/ralph-all.md" "$CODEX_PROMPTS_DIR/"
cp "$PROJECT_DIR/codex-prompts/ralph-spec.md" "$CODEX_PROMPTS_DIR/"

echo -e "${GREEN}Done!${NC}"
echo ""
echo "Installed prompts:"
echo "  - ralph-all.md   -> Process all specs sequentially"
echo "  - ralph-spec.md  -> Process a single spec"
echo ""
echo "Usage in Codex CLI:"
echo -e "  ${BLUE}/prompts:ralph-all${NC}                          # Run all specs"
echo -e "  ${BLUE}/prompts:ralph-spec SPEC_NAME=001-project-setup${NC}  # Run single spec"
echo ""
echo "Usage from command line (non-interactive):"
echo -e "  ${BLUE}codex exec \"/prompts:ralph-all\"${NC}"
echo -e "  ${BLUE}codex exec \"/prompts:ralph-spec SPEC_NAME=001-project-setup\"${NC}"
echo ""
echo -e "${YELLOW}Note: Restart Codex CLI to load the new prompts.${NC}"
