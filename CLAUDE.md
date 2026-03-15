# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a tool for creating OpenCode skill packages. It provides an interactive wizard that generates either classic skill-only projects or first-stage knowledge-hybrid projects with a manifest-first package structure, install/uninstall scripts, and optional git initialization.

## Architecture

### Development-Deployment Separation Pattern

This tool implements a strict separation between development and deployment:

- **Development**: `~/Project/Skills/opencode-skill-*/` - Full project with scripts, docs, version controlled
- **Deployment**: `~/.config/opencode/skills/*/` - Installed skill package files used by OpenCode/tooling

Canonical metadata now lives in `SKILL.toml`, while `SKILL.md` is the human/agent-readable instruction document.

### Key Components

- `create-skill.sh` - Main wizard script. Prompts for metadata, validates inputs, generates files for skill-only or knowledge-hybrid templates. Symlinked to `~/.local/bin/opencode-create-skill`
- `SKILL.toml` - Canonical machine-readable manifest used by package-manager tooling
- `SKILL.md` - Human/agent-readable instruction document with a lightweight compatibility header
- `install.sh` / `uninstall.sh` - Deploy/remove the skill from `~/.config/opencode/skills/`

### Generated Project Structure

Each created skill follows this structure at minimum:

```
opencode-skill-{name}/
├── SKILL.toml            # Canonical machine-readable manifest
├── SKILL.md              # Core skill instructions (installed to ~/.config/opencode/skills/)
├── install.sh            # Deploys skill package files to ~/.config/opencode/skills/
├── uninstall.sh          # Removes skill from ~/.config/opencode/skills/
├── README.md             # Project documentation (not installed)
└── .git/                 # Version control
```

Knowledge-hybrid packages additionally include:

```text
commands/
scripts/
templates/
```

These establish a workflow-entry surface (`save/search/load`) plus deterministic helpers and starter document templates.

## Commands

### Install this tool
```bash
./install.sh
```

Creates `~/.local/bin/opencode-create-skill` symlink and installs the skill.

### Create a new skill
```bash
# Interactive mode (prompts for all metadata)
opencode-create-skill

# Quick mode (skips name prompt)
opencode-create-skill <skill-name>
```

### Uninstall this tool
```bash
./uninstall.sh
```

## Skill Manifest Schema

Generated packages include canonical metadata in `SKILL.toml` with this structure:

```toml
manifest_version = "1.0"

[skill]
name = "skill-name"
version = "0.1.0"
description = "Use when..."
type = "technique"
category = "engineering"
boundary = "One sentence describing scope"
maturity = "draft"
last_verified = "2026-03-14"
tags = ["keyword1"]
topics = ["theme1"]
non_goals = ["out-of-scope item"]
```

### Skill Types

- **technique** - Step-by-step method (concrete process)
- **pattern** - Mental model (way of thinking)
- **reference** - API docs, syntax guides
- **discipline** - Rules/requirements to enforce

### Hybrid Metadata

When the `knowledge-hybrid` template mode is selected, generated manifests also include:

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

This is intended to align future generated packages with package-manager-aware tooling.

## Environment Variables

```bash
# Override default development directory (default: ~/Project/Skills)
export OPENCODE_SKILLS_DEV_DIR="$HOME/custom/path"
```

## Naming Conventions

Skill names must match: `^[a-z0-9]+(-[a-z0-9]+)*$`

- Only lowercase letters, numbers, hyphens
- Must start with letter or number
- Max 50 characters
- Prefix `opencode-skill-` is auto-added to directory names

## File Generation Logic

The wizard (`create-skill.sh`) generates different SKILL.md content based on skill type and template mode:

- **technique**: "Core Technique" section with numbered steps and example
- **pattern**: "The Pattern" section with Before/After comparison
- **reference**: "Quick Reference" table and "Common Operations"
- **discipline**: "The Rule", "Red Flags", "Common Rationalizations" table

All types include: Overview, When to Use, Boundary, Non-Goals, Common Mistakes, See Also.

Knowledge-hybrid mode additionally generates:

- command docs for namespaced `save/search/load`
- helper scripts for those commands
- a starter `templates/knowledge-entry.md`
- hybrid contract documentation in both `SKILL.md` and `README.md`

## Important Notes

- The wizard auto-suggests `tags` and `topics` based on skill name, category, description, and boundary. Authors can accept or override.
- The `description` field should start with "Use when" for OpenCode/tooling discovery.
- Git initialization is optional but recommended (wizard prompts for it).
- The install script copies both `SKILL.toml` and `SKILL.md`, plus optional runtime directories when they exist (`supporting/`, `commands/`, `scripts/`, `templates/`, `docs/`).
- Hybrid packages should treat installed runtime assets as deployable artifacts, while mutable knowledge data should live outside the installed package path.
