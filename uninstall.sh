#!/bin/bash
#
# uninstall.sh - Remove skill from ~/.config/opencode/skills
#

set -e

SKILL_NAME="create-skill"
TARGET_DIR="$HOME/.config/opencode/skills/$SKILL_NAME"
BIN_LINK="$HOME/.local/bin/opencode-create-skill"

if [[ ! -d "$TARGET_DIR" ]]; then
    echo "Skill not installed: $SKILL_NAME"
    exit 0
fi

echo "Removing skill: $SKILL_NAME"

# Remove symlink if exists
if [[ -L "$BIN_LINK" ]]; then
    rm "$BIN_LINK"
    echo "✓ Removed command: opencode-create-skill"
fi

# Remove skill directory
rm -rf "$TARGET_DIR"

echo "✓ Skill uninstalled from: $TARGET_DIR"
