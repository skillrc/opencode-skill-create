# opencode-skill-create

Interactive wizard for creating new OpenCode skill packages with proper project structure, install/uninstall scripts, version control support, and first-stage knowledge-hybrid scaffolding.

## Features

- **Interactive wizard** - Guides you through skill creation
- **Automatic naming validation** - Ensures skill names follow OpenCode conventions
- **Metadata-aware templates** - Creates `SKILL.toml` + `SKILL.md` with a manifest-first package layout
- **Template modes** - Supports both `skill-only` and `knowledge-hybrid`
- **Hybrid scaffolding** - Generates namespaced `save/search/load` commands, scripts, and starter templates
- **Install/uninstall scripts** - One-command deployment
- **Git integration** - Optional automatic repository initialization
- **Command symlink** - Adds `opencode-create-skill` to PATH

## Installation

```bash
cd ~/Project/Skills/opencode-skill-create
./install.sh
```

This will:
1. Install the skill to `~/.config/opencode/skills/create-skill/`
2. Create the command `opencode-create-skill` in `~/.local/bin/`

## Usage

### Interactive Mode

```bash
opencode-create-skill
```

The wizard will prompt for:
- Skill name (e.g., `git-workflow`)
- Description (should start with "Use when...")
- Template mode (`skill-only` or `knowledge-hybrid`)
- Skill type (Technique/Pattern/Reference/Discipline)
- Primary category (engineering/frontend/backend/etc.)
- Boundary sentence describing what the skill covers
- AI-suggested tags and topics, with manual confirmation or override
- Maturity level (draft/alpha/beta/stable/deprecated)
- Git initialization preference

When `knowledge-hybrid` is selected, the wizard also asks for:
- Command namespace
- Data-dir contract / default storage path

### Quick Mode

```bash
opencode-create-skill git-workflow
```

Skips the name prompt, goes straight to other questions.

## Project Structure

The wizard creates projects like this.

### skill-only

```
~/Project/Skills/
└── opencode-skill-{name}/
    ├── SKILL.toml            # Canonical manifest for package managers
    ├── SKILL.md              # Core skill instructions (installed)
    ├── install.sh            # Deploys skill
    ├── uninstall.sh          # Removes skill
    ├── README.md             # Project docs
    └── .git/                 # Version control
```

### knowledge-hybrid

```
~/Project/Skills/
└── opencode-skill-{name}/
    ├── SKILL.toml            # Canonical manifest with [hybrid] + [knowledge]
    ├── SKILL.md              # Core skill and hybrid contract instructions
    ├── commands/             # Namespaced save/search/load command docs
    ├── scripts/              # Helper shell scripts for those commands
    ├── templates/            # Starter knowledge-entry template
    ├── install.sh            # Deploys runtime assets
    ├── uninstall.sh          # Removes installed runtime assets
    ├── README.md             # Project docs
    └── .git/                 # Version control
```

## Development-Deployment Separation

This tool implements the "dev-deploy separation" pattern:

- **Development**: `~/Project/Skills/opencode-skill-*/` - Full project, version controlled
- **Deployment**: `~/.config/opencode/skills/*/` - Installed skill package files used by OpenCode/tooling

**Benefits:**
- Skills are version controlled independently
- Multiple people can collaborate on skill development
- Clean separation between source and runtime
- Easy to uninstall without losing source

## Environment Variables

```bash
# Override default development directory
export OPENCODE_SKILLS_DEV_DIR="$HOME/Project/Skills"
```

## Naming Conventions

Skill names must follow OpenCode conventions:
- Only lowercase letters, numbers, and hyphens
- Start with letter or number
- No spaces or special characters
- Max 50 characters

**Good examples:**
- `git-workflow`
- `code-review`
- `session-journal`
- `tdd-workflow`

## Metadata Schema

Generated packages now include canonical metadata in `SKILL.toml` plus a lightweight compatibility block in `SKILL.md`.

`tags` and `topics` are required in the generated schema, but the wizard now suggests them automatically from the skill name, description, category, and boundary. Authors can accept the suggestions or replace them.

### Required manifest fields
- `manifest_version`
- `[skill].name`
- `[skill].version`
- `[skill].description`
- `[skill].type`
- `[skill].category`
- `[skill].tags`
- `[skill].topics`
- `[skill].boundary`
- `[skill].maturity`
- `[skill].last_verified`

### Optional fields
- `non_goals`

### Hybrid-only fields

When the `knowledge-hybrid` template is selected, the wizard also emits:

- `[hybrid].enabled`
- `[hybrid].mode`
- `[hybrid].command_namespace`
- `[hybrid].generated_commands`
- `[hybrid].data_dir_contract`
- `[knowledge].enabled`
- `[knowledge].storage_format`
- `[knowledge].data_dir`
- `[knowledge].default_index`
- `[knowledge].templates_dir`
- `[knowledge].commands_dir`
- `[knowledge].scripts_dir`

### Example

```toml
manifest_version = "1.0"

[skill]
name = "git-workflow"
version = "0.1.0"
description = "Use when planning safe git commits, history cleanup, or atomic change grouping"
type = "technique"
category = "engineering"
boundary = "Focused on local git hygiene, commit planning, and safe history editing"
maturity = "beta"
last_verified = "2026-03-14"
tags = ["git", "workflow"]
topics = ["version-control"]
non_goals = ["Teaching Git fundamentals"]
```

This metadata makes skills easier to manage, search, group, validate, and install without forcing package tooling to parse Markdown.

## Knowledge-Hybrid Contract

The first-stage hybrid mode is designed to work well with future package-manager integration.

- Commands act as workflow entrypoints.
- `SKILL.md` remains the method and behavioral guide.
- Scripts handle deterministic filesystem work.
- Mutable knowledge data is expected to live outside the installed runtime package.

Recommended default contract:

```bash
${XDG_DATA_HOME:-$HOME/.local/share}/opencode/<namespace>
```

This keeps runtime assets installable while allowing knowledge data to remain mutable.

## Uninstallation

```bash
./uninstall.sh
```

Removes both the skill and the command.

## License

MIT
