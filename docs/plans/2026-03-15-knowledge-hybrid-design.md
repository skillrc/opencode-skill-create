# Design Document: Knowledge-Hybrid Template Evolution

**Date:** 2026-03-15  
**Project:** opencode-skill-create  
**Status:** Draft  
**Author:** AI Assistant  

---

## 1. Context and Current State

### What Exists Today

The `opencode-skill-create` project provides an interactive wizard for scaffolding new OpenCode skills. It generates skill-only projects with the following characteristics:

- **Structure:** SKILL.toml (manifest) + SKILL.md (instructions) + install/uninstall scripts
- **Pattern:** Development-deployment separation (~/Project/Skills/ vs ~/.config/opencode/skills/)
- **Metadata:** Machine-readable TOML with human-readable Markdown overlay
- **Scope:** Single-purpose skills with focused boundaries

### Current Project Template

```
opencode-skill-{name}/
├── SKILL.toml            # Canonical manifest
├── SKILL.md              # Instructions for AI/agent
├── install.sh            # Deploy to ~/.config/opencode/skills/
├── uninstall.sh          # Remove deployment
├── README.md             # Human project docs
└── .git/                 # Version control
```

### The Gap

Skills work well for procedural knowledge (how to do X), but struggle with:
- **Accumulating state** across sessions (research findings, decisions, context)
- **Structured retrieval** of previously captured knowledge
- **Hybrid workflows** where AI performs work and scripts manage storage
- **Cross-session continuity** without relying on conversation context

This design addresses the evolution from skill-only scaffolding to support **knowledge-hybrid templates** that combine AI-driven capture with script-managed persistence.

---

## 2. Goals

### Primary Goals

1. **Enable knowledge capture workflows** - Support skills that need to save, search, and load structured data across sessions
2. **Introduce knowledge-hybrid template** - Add a new template type alongside existing skill-only scaffolding
3. **Maintain backward compatibility** - Existing skill-only projects continue to work unchanged
4. **Explicit boundary between AI and script** - Clear contract: AI generates/validates content, scripts handle storage I/O
5. **File-based state management** - Use markdown files for plans, findings, and progress tracking

### Secondary Goals

6. **Minimal viable first stage** - Ship a working template before adding advanced features
7. **Leverage existing patterns** - Build on lessons from OpenCode and oh-my-openagent workflows
8. **Preserved installer behavior** - Installation remains a simple copy operation
9. **Support research workflows** - First use case: research skills with save/search/load commands

---

## 3. Non-Goals

### Out of Scope for First Stage

1. **Database backends** - Stick to file-based storage (markdown, TOML, JSON)
2. **Complex query languages** - Simple grep/awk-level search, not SQL or full-text search
3. **Multi-user synchronization** - Single-user local workflows only
4. **Cloud storage integration** - Local filesystem only
5. **Real-time collaboration** - No concurrent editing or conflict resolution
6. **Rich media storage** - Text and lightweight structured data only
7. **Plugin architecture** - No extensible command system yet
8. **Automatic migration** - Users manually opt into new templates

### Future Considerations (Not Now)

- Sync with remote git repositories
- Rich metadata indexing
- Cross-project knowledge linking
- Automated knowledge graph generation

---

## 4. Design Principles (Learned from OpenCode/oh-my-openagent)

### 4.1 Command as Workflow Entry

**Pattern:** Scripts provide commands that serve as entry points for workflows. AI handles the complex decision-making, scripts handle the mechanical execution.

**Application:** The knowledge-hybrid template generates a command family (save/search/load) that scripts implement but AI invokes through skill instructions.

**Example:**
```bash
# Script provides the mechanism
research-save --project my-study --type finding --content "..."

# AI decides when and what to save based on conversation context
```

### 4.2 Skill as Method

**Pattern:** SKILL.md defines the method - when to use, how to apply, what to avoid. It is the interface contract between user intent and tool capability.

**Application:** The knowledge-hybrid template includes SKILL.md instructions that guide AI on when to invoke save/search/load commands and how to structure knowledge entries.

### 4.3 Hybrid Packaging

**Pattern:** A single project contains both AI-facing content (SKILL.md) and human-facing tooling (scripts, commands).

**Application:** Knowledge-hybrid projects include:
- SKILL.md for AI instructions on knowledge management
- Command scripts for save/search/load operations
- Template files for consistent knowledge capture

### 4.4 Explicit AI-vs-Script Boundary

**Pattern:** Clear separation of concerns - AI handles interpretation, generation, and validation; scripts handle file I/O, parsing, and formatting.

**Contract:**
| AI Responsibilities | Script Responsibilities |
|---------------------|-------------------------|
| Generate content | Write to filesystem |
| Validate structure | Read from filesystem |
| Decide what to capture | Search and filter |
| Format for context | Parse and present |

**Critical Rule:** Scripts never make semantic decisions. They only execute operations AI has requested.

### 4.5 File-Based Plans and State

**Pattern:** Use markdown files as the source of truth for plans, findings, and progress. Human-readable, version-controllable, simple.

**Application:** Knowledge-hybrid template includes standard files:
- `task_plan.md` - Structured plan with phases and tasks
- `findings.md` - Captured knowledge entries
- `progress.md` - Current state and blockers

### 4.6 Minimal First-Stage Scope

**Pattern:** Ship the smallest useful thing. Add complexity only after validation.

**Application:** First stage supports only:
- One knowledge type (findings/entries)
- Simple append-only storage
- Basic search by keyword and date
- Single-project scope

### 4.7 Preserving Compatibility

**Pattern:** New features are additive. Existing workflows continue unchanged.

**Application:**
- Skill-only template remains the default
- Knowledge-hybrid is opt-in via explicit flag or wizard choice
- Existing installed skills work without modification

---

## 5. Proposed Architecture

### 5.1 Template Selection

The wizard gains a new question:

```
Select template type:
  1) skill-only      - Traditional skill with instructions only
  2) knowledge-hybrid - Skill + knowledge capture commands

Choice (1-2, default 1): 
```

### 5.2 Knowledge-Hybrid Project Structure

```
opencode-skill-{name}/
├── SKILL.toml              # Canonical manifest (extended for hybrid)
├── SKILL.md                # AI instructions including save/search/load guidance
├── commands/
│   ├── save                # Save knowledge entry
│   ├── search              # Search knowledge base
│   ├── load                # Load specific entry or list
│   └── _lib.sh             # Shared shell functions
├── templates/
│   ├── entry.md            # Template for new knowledge entries
│   └── plan.md             # Template for task plans
├── docs/                   # Generated knowledge storage
│   └── .gitkeep            # Ensure directory exists
├── install.sh              # Deploy commands and SKILL.md
├── uninstall.sh            # Remove deployment
├── README.md               # Human project docs
└── .git/
```

### 5.3 Runtime Structure (Post-Install)

```
~/.config/opencode/skills/{skill-name}/
├── SKILL.toml              # Copied from project
├── SKILL.md                # Copied from project
├── commands/               # Copied from project
│   ├── save
│   ├── search
│   ├── load
│   └── _lib.sh
└── templates/              # Copied from project
    ├── entry.md
    └── plan.md
```

Knowledge storage (`docs/`) stays in the project directory (~/Project/Skills/), not the install directory. This preserves the dev-deploy separation: commands are deployed, data stays with the project.

### 5.4 SKILL.toml Extensions

```toml
manifest_version = "1.0"

[skill]
name = "research-session"
version = "0.1.0"
description = "Use when conducting research that needs to be captured and retrieved across sessions"
type = "technique"
category = "research"
boundary = "Focused on knowledge capture, storage, and retrieval for research workflows"
maturity = "draft"
last_verified = "2026-03-15"
tags = ["research", "knowledge", "session"]
topics = ["knowledge-management"]

# NEW: Hybrid-specific metadata
[hybrid]
enabled = true
knowledge_types = ["finding", "decision", "reference"]
storage_format = "markdown"
command_namespace = "research"

[source]
repository = "https://github.com/your-org/opencode-skill-research-session"
license = "MIT"

[compat]
min_opencode_version = "0.1.0"
```

---

## 6. Command Family

### 6.1 Overview

Three core commands form the knowledge management interface:

| Command | Purpose | AI Role | Script Role |
|---------|---------|---------|-------------|
| `save` | Capture new knowledge | Generate content, determine type | Write to file, assign ID |
| `search` | Find existing knowledge | Formulate query, interpret results | Search files, return matches |
| `load` | Retrieve specific entries | Request by ID or filter | Read file, return content |

### 6.2 Command: save

**Usage:**
```bash
{skill-name}-save --type TYPE --content "..." [--tags tag1,tag2] [--project PROJECT]
```

**Behavior:**
1. Validate required flags (--type, --content)
2. Generate timestamp and entry ID
3. Render entry through template
4. Append to `docs/findings.md` or type-specific file
5. Output confirmation with entry ID

**Template (entry.md):**
```markdown
## Entry {id} - {timestamp}

**Type:** {type}  
**Tags:** {tags}  
**Project:** {project}

{content}

---
```

**Example:**
```bash
research-save --type finding \
  --content "OpenCode uses command-as-entry pattern for workflow scaffolding" \
  --tags opencode,architecture,pattern \
  --project knowledge-hybrid-design

# Output:
# ✓ Saved entry res-20260315-001 to docs/findings.md
```

### 6.3 Command: search

**Usage:**
```bash
{skill-name}-search [--query "..."] [--type TYPE] [--tags tag1,tag2] [--since DATE]
```

**Behavior:**
1. Parse query and filters
2. Search through knowledge files
3. Return matching entry IDs with summaries
4. Support simple keyword and date filtering

**Search Strategy (MVP):**
- Use grep for keyword matching
- Parse frontmatter for type/tag filtering
- Date filtering via filename or frontmatter timestamp

**Example:**
```bash
research-search --query "command-as-entry" --type finding

# Output:
# Found 2 entries:
#   res-20260315-001 - OpenCode uses command-as-entry...
#   res-20260315-003 - Commands provide entry points...
```

### 6.4 Command: load

**Usage:**
```bash
{skill-name}-load --id ID               # Load specific entry
{skill-name}-load --list [--limit N]    # List recent entries
{skill-name}-load --project PROJECT     # Load all entries for project
```

**Behavior:**
1. Look up entry by ID or filter
2. Return full content formatted for AI consumption
3. Support list mode for browsing

**Example:**
```bash
research-load --id res-20260315-001

# Output:
## Entry res-20260315-001 - 2026-03-15T10:30:00Z
#
# **Type:** finding
# **Tags:** opencode,architecture,pattern
# **Project:** knowledge-hybrid-design
#
# OpenCode uses command-as-entry pattern for workflow scaffolding
```

### 6.5 Shared Library (_lib.sh)

Common functions used by all commands:

```bash
# _lib.sh - Shared utilities for knowledge commands

# Configuration
get_knowledge_dir() { ... }      # Return docs/ path
get_template() { ... }           # Return template file path
validate_type() { ... }          # Check if type is allowed

# Entry operations
generate_id() { ... }            # Generate unique entry ID
parse_entries() { ... }          # Parse findings.md into structured data
format_entry() { ... }           # Render template with data

# Search operations
search_by_keyword() { ... }      # Grep-based keyword search
search_by_tag() { ... }          # Filter by tags
search_by_date() { ... }         # Filter by date range
```

---

## 7. Data and Storage Model

### 7.1 Storage Philosophy

- **Append-only primary storage** - Never modify historical entries
- **Markdown as source of truth** - Human-readable, git-friendly
- **Simple structure over performance** - Optimize for clarity, not query speed
- **Project-scoped** - Each knowledge-hybrid project has its own storage

### 7.2 File Organization

```
docs/
├── findings.md           # Primary knowledge store (append-only)
├── decisions.md          # Decisions log (optional, if type="decision")
├── references.md         # Reference materials (optional)
├── plan.md               # Current task plan
└── progress.md           # Progress tracking
```

### 7.3 Entry Format

Each entry is a markdown section with YAML frontmatter:

```markdown
## Entry {id}

**ID:** {id}  
**Type:** {type}  
**Created:** {iso_timestamp}  
**Tags:** {comma_separated_tags}  
**Project:** {project_name}

{content_body}

---
```

**Example:**
```markdown
## Entry res-20260315-001

**ID:** res-20260315-001  
**Type:** finding  
**Created:** 2026-03-15T10:30:00Z  
**Tags:** opencode,architecture,pattern  
**Project:** knowledge-hybrid-design

OpenCode uses command-as-entry pattern where scripts provide workflow entry points and AI handles the complex decision-making.

---
```

### 7.4 ID Generation

Format: `{prefix}-{YYYYMMDD}-{sequence}`

- Prefix: Skill-specific (e.g., "res" for research, "dev" for development)
- Date: ISO date without separators
- Sequence: Three-digit daily counter (001, 002, ...)

**Collision handling:** Increment sequence until unique.

### 7.5 Search Index (Future)

For first stage, search is linear file scanning. Future stages may add:
- JSON index file for faster lookups
- Tag-based inverted index
- Full-text search with trigram indexing

---

## 8. Installer Behavior

### 8.1 Installation Flow

```bash
./install.sh
```

**Steps:**
1. Parse SKILL.toml for skill name and hybrid configuration
2. Create target directory: `~/.config/opencode/skills/{name}/`
3. Copy SKILL.md and SKILL.toml
4. If hybrid enabled:
   - Copy `commands/` directory recursively
   - Copy `templates/` directory recursively
   - Create symlinks for commands in `~/.local/bin/`
5. Output summary

### 8.2 Command Symlinks

For knowledge-hybrid skills, create symlinks:

```bash
# From ~/.local/bin/ -> ~/.config/opencode/skills/{name}/commands/
ln -sf "$TARGET_DIR/commands/save" "$BIN_DIR/{skill-name}-save"
ln -sf "$TARGET_DIR/commands/search" "$BIN_DIR/{skill-name}-search"
ln -sf "$TARGET_DIR/commands/load" "$BIN_DIR/{skill-name}-load"
```

### 8.3 Uninstallation

```bash
./uninstall.sh
```

**Steps:**
1. Remove target directory
2. Remove command symlinks
3. Preserve project directory (~/Project/Skills/) with all data

**Important:** Knowledge data (docs/) is never deleted during uninstall. It lives in the project directory, not the install directory.

---

## 9. Generator Changes

### 9.1 Wizard Modifications

The `create-skill.sh` wizard needs updates:

1. **New question:** Template type selection (skill-only vs knowledge-hybrid)
2. **Conditional prompts:** Only ask hybrid-specific questions if type=knowledge-hybrid
3. **Extended metadata:** Capture knowledge_types, storage_format
4. **New generators:** Generate command scripts and templates

### 9.2 New Generator Functions

```bash
# Generate command scripts
generate_save_command() { ... }
generate_search_command() { ... }
generate_load_command() { ... }
generate_lib_shared() { ... }

# Generate templates
generate_entry_template() { ... }
generate_plan_template() { ... }

# Generate project structure
generate_commands_dir() { ... }
generate_templates_dir() { ... }
generate_docs_dir() { ... }
```

### 9.3 Template Variable Injection

Command scripts are templates with placeholders:

```bash
#!/bin/bash
# {skill-name}-save
# Generated from template

SKILL_NAME="{skill_name}"
KNOWLEDGE_DIR="{project_dir}/docs"
TEMPLATE_FILE="{project_dir}/templates/entry.md"
ALLOWED_TYPES=({knowledge_types})

# ... implementation
```

---

## 10. Phased Rollout

### Phase 1: Foundation (This Design)

**Goal:** Working knowledge-hybrid template with save/search/load

**Deliverables:**
- [ ] SKILL.toml extension for hybrid metadata
- [ ] Command family implementation (save/search/load)
- [ ] Entry template and storage format
- [ ] Updated wizard with template selection
- [ ] Installer support for commands/ directory
- [ ] Documentation and examples

**Scope:** Single knowledge type (findings), simple keyword search

### Phase 2: Enhanced Search

**Goal:** Richer query capabilities

**Deliverables:**
- [ ] Multi-type support (findings, decisions, references)
- [ ] Tag-based filtering
- [ ] Date range queries
- [ ] Cross-reference linking

### Phase 3: Advanced Features

**Goal:** Production-ready knowledge management

**Deliverables:**
- [ ] JSON index for performance
- [ ] Knowledge graph generation
- [ ] Export/import functionality
- [ ] Template marketplace

---

## 11. Risks and Tradeoffs

### 11.1 Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| **Scope creep** | Medium | Strict first-stage boundaries, explicit non-goals |
| **Breaking existing skills** | High | Skill-only remains default, hybrid is opt-in |
| **Complexity overwhelming users** | Medium | Clear documentation, simple examples |
| **File-based limits performance** | Low | Acknowledged; acceptable for first stage |
| **AI-script boundary confusion** | Medium | Explicit SKILL.md guidance, clear contracts |

### 11.2 Tradeoffs

| Decision | Pros | Cons |
|----------|------|------|
| **File-based vs database** | Simple, version-controllable, human-readable | Slower search, no concurrent access |
| **Project-scoped vs global storage** | Isolation, clarity | No cross-project knowledge sharing |
| **Append-only vs editable** | Audit trail, simplicity | Cannot correct mistakes in place |
| **Shell scripts vs Python** | Universal, no dependencies | Harder to write complex logic |
| **Symlinked commands vs PATH modification** | Explicit, removable | Pollutes bin directory |

### 11.3 Open Questions

1. Should knowledge be shareable across projects (global storage option)?
2. How to handle large knowledge bases (thousands of entries)?
3. Should entries support attachments or linked files?
4. What is the migration path from skill-only to hybrid?

---

## 12. Acceptance Criteria

### 12.1 Functional Requirements

- [ ] Wizard can generate both skill-only and knowledge-hybrid projects
- [ ] Knowledge-hybrid projects include save/search/load commands
- [ ] Commands are symlinked to ~/.local/bin/ on install
- [ ] Save command appends formatted entry to docs/findings.md
- [ ] Search command returns matching entry IDs
- [ ] Load command returns full entry content
- [ ] Skill-only projects work exactly as before
- [ ] Uninstall removes commands but preserves project data

### 12.2 Quality Requirements

- [ ] All scripts have error handling (set -e)
- [ ] Commands validate inputs and provide helpful error messages
- [ ] Generated code follows shell scripting best practices
- [ ] Documentation includes usage examples
- [ ] Templates are clear and well-commented

### 12.3 Compatibility Requirements

- [ ] Existing opencode-create-skill command works unchanged
- [ ] Existing skill-only projects install/uninstall correctly
- [ ] No changes to default behavior (skill-only is default)
- [ ] Bash 4.0+ compatible (no exotic dependencies)

### 12.4 Documentation Requirements

- [ ] SKILL.md updated with knowledge-hybrid instructions
- [ ] README.md explains template differences
- [ ] Example projects demonstrate save/search/load workflow
- [ ] Migration guide for skill-only to hybrid (optional)

---

## 13. Appendix

### 13.1 Glossary

| Term | Definition |
|------|------------|
| **Knowledge-hybrid** | Template combining AI-facing skill instructions with script-managed knowledge storage |
| **Command family** | Related commands (save/search/load) that work together |
| **Entry** | Single unit of captured knowledge with metadata |
| **SKILL.toml** | Machine-readable skill manifest |
| **Dev-deploy separation** | Pattern keeping source in ~/Project/Skills/ and runtime in ~/.config/opencode/skills/ |

### 13.2 Related Work

- OpenCode command-as-entry pattern
- Oh-my-openagent workflow scaffolding
- Session journal persistence patterns
- Zettelkasten note-taking methodology

### 13.3 References

- [OpenCode Documentation](https://docs.opencode.ai)
- [Oh-my-openagent Workflows](https://github.com/ohmypvr/workflows)
- [Zettelkasten Method](https://zettelkasten.de)

---

## 14. Change Log

| Date | Version | Changes |
|------|---------|---------|
| 2026-03-15 | 0.1.0 | Initial design document |

---

**End of Document**
