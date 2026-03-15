# Hybrid Compatibility Contract Draft

**Date:** 2026-03-15  
**Projects:** `opencode-skill-create` ↔ `opencode-skill-management`  
**Status:** Draft  
**Purpose:** Define the minimum cross-project contract needed for generated knowledge-hybrid packages to work cleanly with Skillmine-style install/sync workflows.

---

## 1. Why This Contract Exists

`opencode-skill-create` is evolving from a skill-only scaffolder into a generator that can produce **knowledge-hybrid packages**: a package that includes:

- `SKILL.toml` as canonical machine-readable metadata
- `SKILL.md` as AI-facing method/instructions
- `commands/` as workflow entrypoints
- `scripts/` as deterministic runtime helpers

`opencode-skill-management` (Skillmine) is a **package manager / installer / sync engine** for AI assistant skills. It already understands manifest-first skill packages and syncs them into assistant runtime directories.

The integration goal is:

> Let `opencode-skill-create` generate hybrid packages that `opencode-skill-management` can install, inspect, validate, and sync without ambiguity.

---

## 2. Design Principles Carried Forward

These principles come directly from the workflow lessons learned from OpenCode and oh-my-openagent:

### 2.1 Command as Workflow Entry

Commands are not just convenience wrappers. They are explicit entry points into a workflow.

In hybrid packages:

- `save` starts knowledge capture
- `search` starts retrieval
- `load` starts recall / reuse

### 2.2 Skill as Method

`SKILL.md` should define:

- when to use the hybrid package
- when to invoke `save/search/load`
- how AI and scripts divide responsibilities

### 2.3 AI / Script Boundary

AI owns:

- interpretation
- structuring
- validation prompts
- semantic summarization

Scripts own:

- filesystem paths
- persistence
- indexing
- deterministic loading / searching

### 2.4 Runtime Package vs Mutable Data

Installed package assets should be treated as **deployable runtime artifacts**.

Mutable knowledge data must live outside the installed package tree.

This is the key compatibility rule with Skillmine.

---

## 3. Compatibility Goals

The two systems should divide responsibilities cleanly.

### `opencode-skill-create` should own

- package scaffolding
- manifest generation
- command and script scaffolding
- authoring-time documentation

### `opencode-skill-management` should own

- package resolution
- installation
- syncing to assistant runtime targets
- lockfile and cache management
- health checks / diagnostics

### Shared contract surface

- `SKILL.toml`
- hybrid metadata extension
- data directory resolution rules
- command namespace rules

---

## 4. Proposed `SKILL.toml` Hybrid Extension

This draft extends the existing manifest format without breaking existing skill-only packages.

## Base manifest remains unchanged

```toml
manifest_version = "1.0"

[skill]
name = "research-notes"
version = "0.1.0"
description = "Use when capturing, searching, and loading structured research knowledge"
type = "workflow"
category = "research"
boundary = "Focused on local knowledge capture and retrieval for research workflows"
maturity = "alpha"
last_verified = "2026-03-15"
tags = ["research", "knowledge", "notes"]
topics = ["knowledge-management", "workflow"]
non_goals = ["Multi-user collaboration", "Remote synchronization"]

[compat]
min_opencode_version = "0.1.0"
min_skillmine_version = "0.1.0"
```

## New hybrid section

```toml
[hybrid]
enabled = true
kind = "knowledge"
command_namespace = "research"
commands = ["save", "search", "load"]
storage_mode = "external-data-dir"
storage_format = "markdown-frontmatter"
default_scope = "user"
```

## Optional knowledge section

```toml
[knowledge]
entry_types = ["finding", "decision", "reference"]
index_files = ["entries.json", "tags.json", "topics.json"]
default_entry_template = "templates/entry.md"
```

---

## 5. Meaning of New Fields

### `[hybrid].enabled`

Marks the package as requiring hybrid-aware runtime handling.

### `[hybrid].kind`

Initial discriminator for hybrid package type.

First-stage allowed value:

- `knowledge`

Future possible values:

- `journal`
- `workflow`
- `registry`

### `[hybrid].command_namespace`

Canonical command namespace for the package.

If namespace is `research`, the command family becomes:

- `research-save`
- `research-search`
- `research-load`

This field should be the source of truth for command exposure and collision checks.

### `[hybrid].commands`

Declares the allowed command verbs for the hybrid package.

First stage:

- `save`
- `search`
- `load`

### `[hybrid].storage_mode`

Controls where mutable data should live.

Proposed values:

- `external-data-dir` — preferred default
- `project-relative` — development-only / explicit opt-in

### `[hybrid].storage_format`

Declares persistence format.

First stage:

- `markdown-frontmatter`

### `[hybrid].default_scope`

Declares the default storage scope.

Proposed values:

- `user`
- `project`

First-stage default:

- `user`

### `[knowledge].entry_types`

Declares the kinds of knowledge entries supported.

### `[knowledge].index_files`

Declares the expected index file names so that tooling like Skillmine doctor/info can validate runtime health.

### `[knowledge].default_entry_template`

Points to a package-relative template file that AI or scripts may use when writing new entries.

---

## 6. Data Directory Contract

This is the most important compatibility contract in the entire design.

## Rule

> Hybrid knowledge data MUST NOT default to repo-relative paths or installed runtime-package paths.

Installed package assets are deployable artifacts. Knowledge data is mutable user state.

They must be separated.

## Resolution order

Hybrid commands should resolve the data directory using this precedence:

1. `OPENCODE_SKILL_DATA_DIR`
2. package-specific env var, e.g. `RESEARCH_DATA_DIR`
3. manifest/config-declared user data root
4. XDG-style default
5. explicit development fallback only if requested

### Recommended default path

```text
~/.local/share/opencode-skills/{skill-name}/
```

Example:

```text
~/.local/share/opencode-skills/research-notes/
```

## Required substructure

```text
{data-dir}/
  entries/
  index/
    entries.json
    tags.json
    topics.json
```

## Development-only fallback

If the user explicitly opts into project-local mode during authoring, the generator may allow:

```text
./docs/knowledge/
```

But this must not be the default for generated hybrid packages intended to work with Skillmine.

---

## 7. Runtime Package Contract

Skillmine-compatible hybrid packages should install and sync only runtime assets.

## Runtime assets

- `SKILL.toml`
- `SKILL.md`
- `commands/`
- `scripts/`
- `templates/` or `supporting/` if required at runtime

## Not runtime assets

- mutable knowledge entries
- index files
- project notes
- design docs
- authoring-only docs

## Rule

> Hybrid commands may read from the installed package, but they must write mutable data only to the resolved external data directory.

This preserves compatibility with:

- content-addressable stores
- sync targets
- tmp clone workflows
- GitHub-installed packages

---

## 8. Command Exposure Contract

This contract must answer one question clearly:

> Who owns command shims or command exposure?

## Recommended answer

Long-term, `opencode-skill-management` should be the **installer of record** for command exposure.

That means:

- `opencode-skill-create` generates the package structure and metadata
- generated `install.sh` remains a convenience fallback for local development
- Skillmine becomes responsible for installing/syncing command-facing runtime assets consistently

## First-stage compromise

Until Skillmine supports hybrid command exposure natively:

- generated `install.sh` may still create development-time command shims
- but the manifest must make future Skillmine ownership possible

## Command naming rule

Commands should be derived from:

`{command_namespace}-{verb}`

Examples:

- `research-save`
- `research-search`
- `research-load`

Not from ad hoc combinations of repo name and command name.

---

## 9. Diagnostic / Validation Contract for Skillmine

Once Skillmine becomes hybrid-aware, it should be able to validate at least:

### Manifest checks

- `[hybrid]` exists when hybrid package is declared
- `command_namespace` is present and valid
- `commands` contains only supported verbs
- `storage_mode` is recognized

### Runtime checks

- `commands/` exists
- `scripts/` exists if required
- referenced template files exist

### Data checks

- resolved data directory exists or can be created
- expected index files exist or can be initialized
- installed runtime package is not being used as mutable storage

### Collision checks

- command namespace conflicts
- duplicate hybrid packages claiming the same namespace

---

## 10. What `opencode-skill-create` Should Generate

For a first-stage knowledge-hybrid package, the generator should emit:

```text
opencode-skill-{name}/
├── SKILL.toml
├── SKILL.md
├── commands/
│   ├── {namespace}-save.md
│   ├── {namespace}-search.md
│   └── {namespace}-load.md
├── scripts/
│   ├── {namespace}-save.sh
│   ├── {namespace}-search.sh
│   └── {namespace}-load.sh
├── templates/
│   └── entry.md
├── install.sh
├── uninstall.sh
└── README.md
```

## Generator-specific requirements

- ask for `command_namespace`
- ask whether project-local storage should be enabled for development
- default to external data-dir storage
- emit `[hybrid]` and `[knowledge]` sections into `SKILL.toml`
- explain the data-directory contract in `README.md` and `SKILL.md`

---

## 11. What `opencode-skill-management` Should Eventually Support

Not all of this is required immediately, but this is the intended compatibility arc.

## Phase 1: Tolerate hybrid manifests

- parse and ignore extra `[hybrid]` / `[knowledge]` fields safely
- continue install/sync as normal package directories

## Phase 2: Surface hybrid metadata

- show hybrid info in `info`
- show package type in `list`
- report hybrid readiness in `doctor`

## Phase 3: Manage command exposure

- install command shims from manifest data
- detect namespace conflicts
- report missing scripts or commands

## Phase 4: Validate data contract

- verify data directory rules
- initialize default index structure if missing
- detect bad project-relative assumptions in synced packages

---

## 12. Migration Strategy

This contract should remain additive.

## Existing skill-only packages

- remain valid
- ignore hybrid fields because they do not have them
- continue to install via existing flows

## New hybrid packages

- opt in via `[hybrid].enabled = true`
- should still be installable by older tools as plain directories
- but will gain richer behavior as Skillmine becomes hybrid-aware

This ensures the ecosystem can evolve without breaking legacy skills.

---

## 13. Open Questions

These questions should be settled before implementation is considered complete.

1. Should `command_namespace` be required to equal `skill.name`, or only be unique?
2. Should project-local storage be allowed in generated packages at all, or only as manual author customization?
3. Should generated `install.sh` eventually delegate to Skillmine if available?
4. Should hybrid command metadata live only in `[hybrid]`, or also be duplicated into `commands/*.md` frontmatter for local tooling?
5. Should Skillmine eventually distinguish `skill-only` vs `hybrid` at the package-manager level?

---

## 14. Recommended Immediate Decision

Before implementing knowledge-hybrid support in `opencode-skill-create`, adopt these decisions now:

1. **Default mutable knowledge storage to external data dir**
2. **Make `command_namespace` a first-class generated field**
3. **Keep hybrid metadata additive in `SKILL.toml`**
4. **Treat generated install scripts as fallback, not long-term source of truth**
5. **Design packages so Skillmine can later become hybrid-aware without format breakage**

---

## 15. Bottom Line

The two projects are already philosophically aligned:

- manifest-first packaging
- dev/runtime separation
- OpenCode runtime targeting
- workflow-aware skill ecosystems

The main compatibility challenge is **not package format**.

It is this:

> Hybrid packages introduce mutable knowledge state, while package managers assume installable artifacts are immutable or cacheable.

This contract resolves that tension by separating:

- **runtime package assets** from
- **mutable external knowledge data**

Once that split is respected, `opencode-skill-create` and `opencode-skill-management` should work together very well.
