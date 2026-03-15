OPENCODE-SKILL-CREATE(1)

```text
NAME
       opencode-skill-create - interactive authoring tool for
       OpenCode skill packages

SYNOPSIS
       opencode-create-skill [skill-name]
```

```text
DESCRIPTION
       opencode-skill-create scaffolds manifest-first skill packages in a
       development directory and installs runtime-facing package assets into
       the OpenCode skill runtime.

       It is an upstream authoring tool.

       It does not act as a package manager, lockfile engine, or installer of
       record for multi-package runtime operations.
```

```text
MODES
       +------------------+-------------------------------------------+
       | Mode             | Description                               |
       +------------------+-------------------------------------------+
       | skill-only       | Traditional instruction-only package      |
       | knowledge-hybrid | Skill package with command/template assets|
       +------------------+-------------------------------------------+
```

```text
INSTALLATION
       cd ~/Project/Skills/opencode-skill-create
       ./install.sh

       This installs:
       1. the skill package into ~/.config/opencode/skills/create-skill/
       2. the opencode-create-skill helper command into ~/.local/bin/
```

```bash
QUICK START

# Interactive mode
opencode-create-skill

# Quick mode with name provided up front
opencode-create-skill git-workflow
```

```text
WIZARD INPUTS
       The wizard gathers:

       +------------------+-------------------------------------------+
       | Input            | Purpose                                   |
       +------------------+-------------------------------------------+
       | skill name       | Stable package identifier                 |
       | description      | "Use when..." trigger phrase             |
       | template mode    | skill-only vs knowledge-hybrid            |
       | type             | technique/pattern/reference/discipline    |
       | category         | Primary management bucket                 |
       | boundary         | One-sentence scope contract               |
       | tags/topics      | Discoverability metadata                  |
       | maturity         | Lifecycle stage                           |
       | git init         | Optional repository initialization        |
       +------------------+-------------------------------------------+

       Hybrid mode additionally asks for command namespace and data-dir
       contract inputs.
```

```text
PROJECT LAYOUT
       skill-only package:

       ~/Project/Skills/opencode-skill-{name}/
       +-- SKILL.toml
       +-- SKILL.md
       +-- install.sh
       +-- uninstall.sh
       +-- README.md
       '-- .git/

       knowledge-hybrid package:

       ~/Project/Skills/opencode-skill-{name}/
       +-- SKILL.toml
       +-- SKILL.md
       +-- commands/
       +-- scripts/
       +-- templates/
       +-- install.sh
       +-- uninstall.sh
       +-- README.md
       '-- .git/
```

```text
DEVELOPMENT AND DEPLOYMENT SEPARATION
       Source projects live under the development tree:

              ~/Project/Skills/opencode-skill-*/

       Installed runtime assets live under:

              ~/.config/opencode/skills/*/

       This separation preserves version control, keeps source richer than the
       installed package, and allows reinstall without treating the runtime
       tree as the authoring workspace.
```

```text
MANIFEST MODEL
       Generated packages are manifest-first.

       +------------------+-------------------------------------------+
       | File             | Role                                      |
       +------------------+-------------------------------------------+
       | SKILL.toml       | Canonical machine-readable package truth  |
       | SKILL.md         | Human/agent method surface                |
       +------------------+-------------------------------------------+

       tags and topics are required in output, but may be suggested by the
       tool and confirmed by the author.
```

```toml
MANIFEST EXAMPLE

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

```text
HYBRID PACKAGE NOTES
       knowledge-hybrid is a first-stage package shape intended to align with
       downstream package-management tooling.

       Shared rules:
       - commands are workflow entrypoints
       - SKILL.md remains the method contract
       - scripts handle deterministic filesystem work
       - mutable knowledge data should not default to the installed package tree
```

```bash
RECOMMENDED DATA DIR
${XDG_DATA_HOME:-$HOME/.local/share}/opencode/<namespace>
```

```text
ARCHITECTURE
       Authoring flow:

           User intent
                |
                v
           +------------+
           | Wizard     |
           +------------+
                |
                v
           +------------+
           | SKILL.toml |
           | SKILL.md   |
           | assets     |
           +------------+
                |
                v
           +------------+
           | install.sh |
           +------------+
                |
                v
           ~/.config/opencode/skills/
```

```text
ENVIRONMENT
       OPENCODE_SKILLS_DEV_DIR
              Overrides the default development root.

              Default:
                     ~/Project/Skills
```

```text
FILES
       create-skill.sh
              Main authoring wizard.

       SKILL.toml
              Canonical manifest for this tool itself.

       install.sh
              Installs the tool package and helper command.

       docs/plans/2026-03-15-knowledge-hybrid-design.md
              Hybrid package design notes.

       docs/plans/2026-03-15-hybrid-compatibility-contract.md
              Draft downstream compatibility contract.
```

```text
SEE ALSO
       opencode-skill-spec(1)
       skillmine(1)
       SKILL.toml
       SKILL.md

AUTHORS
       OpenCode contributors

LICENSE
       MIT
```
