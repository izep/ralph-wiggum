#!/bin/bash
#
# Ralph Wiggum setup script
# Copies templates, commands, and scripts into the target project.
#
# Usage:
#   ./scripts/setup.sh                # Install into current directory
#   ./scripts/setup.sh /path/to/project
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
TARGET_DIR="${1:-$(pwd)}"

mkdir -p "$TARGET_DIR/.specify/memory" \
  "$TARGET_DIR/.specify/specs" \
  "$TARGET_DIR/templates" \
  "$TARGET_DIR/scripts" \
  "$TARGET_DIR/.cursor/commands"

if [[ -f "$TARGET_DIR/.specify/memory/constitution.md" ]]; then
  cp "$TARGET_DIR/.specify/memory/constitution.md" "$TARGET_DIR/.specify/memory/constitution.md.bak"
fi

cp "$REPO_DIR/templates/constitution-template.md" "$TARGET_DIR/.specify/memory/constitution.md"
cp "$REPO_DIR/templates/spec-template.md" "$TARGET_DIR/templates/spec-template.md"
cp "$REPO_DIR/templates/checklist-template.md" "$TARGET_DIR/templates/checklist-template.md"

cp "$REPO_DIR/.cursor/commands/speckit.specify.md" "$TARGET_DIR/.cursor/commands/"
cp "$REPO_DIR/.cursor/commands/speckit.implement.md" "$TARGET_DIR/.cursor/commands/"

cp "$REPO_DIR/scripts/ralph-loop.sh" "$TARGET_DIR/scripts/"
cp "$REPO_DIR/scripts/setup-codex-prompts.sh" "$TARGET_DIR/scripts/"

chmod +x "$TARGET_DIR/scripts"/*.sh

echo "Ralph Wiggum installed in: $TARGET_DIR"
