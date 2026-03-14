#!/bin/bash
#
# install.sh - Install skill to ~/.config/opencode/skills
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_NAME="create-skill"
TARGET_DIR="$HOME/.config/opencode/skills/$SKILL_NAME"

echo "Installing skill: $SKILL_NAME"
echo ""

# Create target directory
mkdir -p "$TARGET_DIR"

# Copy SKILL.md
cp "$SCRIPT_DIR/SKILL.md" "$TARGET_DIR/"

# Copy create-skill.sh script
cp "$SCRIPT_DIR/create-skill.sh" "$TARGET_DIR/"
chmod +x "$TARGET_DIR/create-skill.sh"

# Create symlink for easy access
BIN_DIR="$HOME/.local/bin"
if [[ -d "$BIN_DIR" ]]; then
    ln -sf "$TARGET_DIR/create-skill.sh" "$BIN_DIR/opencode-create-skill"
    echo "✓ Created command: opencode-create-skill"
fi

echo ""
echo "✓ Skill installed to: $TARGET_DIR"
echo ""
echo "Usage:"
echo "  Interactive mode:  opencode-create-skill"
echo "  Quick mode:        opencode-create-skill <skill-name>"
echo ""
echo "Example:"
echo "  opencode-create-skill git-workflow"
