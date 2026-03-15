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

mkdir -p "$TARGET_DIR"

cp "$SCRIPT_DIR/SKILL.toml" "$TARGET_DIR/"
cp "$SCRIPT_DIR/SKILL.md" "$TARGET_DIR/"
cp "$SCRIPT_DIR/create-skill.sh" "$TARGET_DIR/"
chmod +x "$TARGET_DIR/create-skill.sh"

for dir_name in templates docs; do
    if [[ -d "$SCRIPT_DIR/$dir_name" ]]; then
        mkdir -p "$TARGET_DIR/$dir_name"
        cp -R "$SCRIPT_DIR/$dir_name/." "$TARGET_DIR/$dir_name/"
    fi
done

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
