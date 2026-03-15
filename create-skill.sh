#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/templates"
SKILLS_DEV_DIR="${OPENCODE_SKILLS_DEV_DIR:-$HOME/Project/Skills}"
SKILL_PREFIX="opencode-skill-"
MANIFEST_VERSION="1.0"

print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}" >&2
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}" >&2
}

print_error() {
    echo -e "${RED}✗ $1${NC}" >&2
}

validate_skill_name() {
    local name="$1"

    if [[ -z "$name" ]]; then
        print_error "Skill name cannot be empty"
        return 1
    fi

    if [[ ! "$name" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
        print_error "Invalid skill name: '$name'"
        echo "   Skill names must:"
        echo "   - Use only lowercase letters, numbers, and hyphens"
        echo "   - Start with a letter or number"
        echo "   - Not contain spaces or special characters"
        echo "   - Examples: git-workflow, code-review, session-journal"
        return 1
    fi

    if [[ ${#name} -gt 50 ]]; then
        print_error "Skill name too long (max 50 characters)"
        return 1
    fi

    return 0
}

validate_command_namespace() {
    local namespace="$1"

    if [[ -z "$namespace" ]]; then
        print_error "Command namespace cannot be empty"
        return 1
    fi

    if [[ ! "$namespace" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
        print_error "Invalid command namespace: '$namespace'"
        echo "   Command namespaces must use lowercase letters, numbers, and hyphens"
        return 1
    fi

    if [[ ${#namespace} -gt 50 ]]; then
        print_error "Command namespace too long (max 50 characters)"
        return 1
    fi

    return 0
}

validate_data_dir_contract() {
    local value="$1"
    if [[ -z "$value" ]]; then
        print_error "Data-dir contract cannot be empty"
        return 1
    fi
    return 0
}

get_skill_name() {
    local name="$1"

    if [[ -n "$name" ]]; then
        name="${name#$SKILL_PREFIX}"
        if validate_skill_name "$name"; then
            echo "$name"
            return 0
        else
            return 1
        fi
    fi

    while true; do
        echo -n "Enter skill name (e.g., 'git-workflow'): " >&2
        read -r name
        name="${name#$SKILL_PREFIX}"

        if validate_skill_name "$name"; then
            echo "$name"
            return 0
        fi
        echo ""
    done
}

get_description() {
    echo -n "Enter skill description (Use when...): " >&2
    read -r description

    if [[ ! "$description" =~ ^[Uu]se[[:space:]]when ]]; then
        description="Use when $description"
    fi

    echo "$description"
}

get_template_mode() {
    echo "Select template mode:" >&2
    echo "  1) skill-only        - Standard OpenCode skill scaffold" >&2
    echo "  2) knowledge-hybrid  - Skill plus namespaced save/search/load knowledge commands" >&2

    while true; do
        echo -n "Choice (1-2, default 1): " >&2
        read -r choice
        choice="${choice:-1}"

        case "$choice" in
            1) echo "skill-only"; return 0 ;;
            2) echo "knowledge-hybrid"; return 0 ;;
            *) print_warning "Please enter 1-2" ;;
        esac
    done
}

get_skill_type() {
    echo "Select skill type:" >&2
    echo "  1) Technique - Concrete method with steps" >&2
    echo "  2) Pattern   - Way of thinking about problems" >&2
    echo "  3) Reference - API docs, syntax guides" >&2
    echo "  4) Discipline - Rules/requirements to follow" >&2

    while true; do
        echo -n "Choice (1-4): " >&2
        read -r choice
        case "$choice" in
            1) echo "technique"; return 0 ;;
            2) echo "pattern"; return 0 ;;
            3) echo "reference"; return 0 ;;
            4) echo "discipline"; return 0 ;;
            *) print_warning "Please enter 1-4" ;;
        esac
    done
}

get_category() {
    echo "Select primary skill category:" >&2
    echo "  1) engineering - General software engineering workflows" >&2
    echo "  2) frontend    - UI, UX, styling, and browser work" >&2
    echo "  3) backend     - APIs, services, and server logic" >&2
    echo "  4) devops      - Infrastructure, deployment, and operations" >&2
    echo "  5) testing     - Unit, integration, and E2E testing" >&2
    echo "  6) security    - Security reviews and hardening" >&2
    echo "  7) research    - Investigation, discovery, and analysis" >&2
    echo "  8) writing     - Documentation and written communication" >&2
    echo "  9) workflow    - Process, collaboration, and productivity" >&2
    echo " 10) product     - Product thinking and strategy" >&2
    echo " 11) general     - Cross-functional or uncategorized" >&2

    while true; do
        echo -n "Choice (1-11): " >&2
        read -r choice
        case "$choice" in
            1) echo "engineering"; return 0 ;;
            2) echo "frontend"; return 0 ;;
            3) echo "backend"; return 0 ;;
            4) echo "devops"; return 0 ;;
            5) echo "testing"; return 0 ;;
            6) echo "security"; return 0 ;;
            7) echo "research"; return 0 ;;
            8) echo "writing"; return 0 ;;
            9) echo "workflow"; return 0 ;;
            10) echo "product"; return 0 ;;
            11) echo "general"; return 0 ;;
            *) print_warning "Please enter 1-11" ;;
        esac
    done
}

get_boundary() {
    local boundary
    echo -n "Enter skill boundary (one sentence describing what it covers): " >&2
    read -r boundary

    while [[ -z "$boundary" ]]; do
        print_warning "Boundary cannot be empty"
        echo -n "Enter skill boundary: " >&2
        read -r boundary
    done

    echo "$boundary"
}

get_metadata_list() {
    local prompt="$1"
    local raw

    echo -n "$prompt: " >&2
    read -r raw

    raw=$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]' | sed 's/, */,/g; s/^,*//; s/,*$//')
    echo "$raw"
}

normalize_metadata_candidates() {
    local raw="$1"
    printf '%s' "$raw" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 -]/ /g; s/[[:space:]]\+/-/g; s/-\{2,\}/-/g; s/^-//; s/-$//'
}

append_csv_item() {
    local csv="$1"
    local item="$2"

    item=$(printf '%s' "$item" | sed 's/^ *//; s/ *$//')
    [[ -z "$item" ]] && {
        echo "$csv"
        return 0
    }

    if [[ ",${csv}," == *",${item},"* ]]; then
        echo "$csv"
    elif [[ -z "$csv" ]]; then
        echo "$item"
    else
        echo "$csv,$item"
    fi
}

build_tag_suggestions() {
    local skill_name="$1"
    local category="$2"
    local description="$3"
    local boundary="$4"
    local template_mode="$5"
    local combined normalized tags_csv token

    combined="$skill_name $category $description $boundary $template_mode"
    normalized=$(normalize_metadata_candidates "$combined")

    tags_csv=""

    for token in $(printf '%s' "$skill_name" | tr '-' ' '); do
        if printf '%s\n' "$token" | grep -Eq '^[a-z0-9]{3,}$' && ! printf '%s\n' "$token" | grep -Eq '^(skill|test|tool|new|create)$'; then
            tags_csv=$(append_csv_item "$tags_csv" "$token")
        fi
    done

    if printf '%s' "$combined" | grep -Eqi '\bworkflow\b'; then tags_csv=$(append_csv_item "$tags_csv" "workflow"); fi
    if [[ "$template_mode" == "knowledge-hybrid" ]]; then
        tags_csv=$(append_csv_item "$tags_csv" "knowledge")
        tags_csv=$(append_csv_item "$tags_csv" "hybrid")
        tags_csv=$(append_csv_item "$tags_csv" "commands")
    fi

    while IFS= read -r token; do
        if printf '%s\n' "$token" | grep -Eq '^[a-z0-9]{4,}$' && ! printf '%s\n' "$token" | grep -Eq '^(use|when|with|from|that|this|your|have|will|then|than|where|which|covers|cover|focused|specific|situation|situations|apply|applies|local|safe|planning|skill|test|does|knowledge|hybrid|command|commands)$'; then
            tags_csv=$(append_csv_item "$tags_csv" "$token")
        fi
    done < <(printf '%s\n' "$normalized" | tr '-' '\n')

    tags_csv=$(printf '%s' "$tags_csv" | awk -F',' '{count=0; for (i=1; i<=NF; i++) {if ($i != "" && count < 6) {if (count > 0) printf ","; printf "%s", $i; count++;}}}')

    if [[ -z "$tags_csv" ]]; then
        tags_csv=$(append_csv_item "$tags_csv" "$category")
        tags_csv=$(append_csv_item "$tags_csv" "workflow")
    fi

    echo "$tags_csv"
}

build_topic_suggestions() {
    local category="$1"
    local skill_type="$2"
    local boundary="$3"
    local description="$4"
    local skill_name="$5"
    local template_mode="$6"
    local anchor_topics=()
    local fallback_topics=()

    case "$category" in
        engineering) fallback_topics+=(software-engineering) ;;
        frontend) fallback_topics+=(frontend-development) ;;
        backend) fallback_topics+=(backend-systems) ;;
        devops) fallback_topics+=(infrastructure-operations) ;;
        testing) fallback_topics+=(software-testing) ;;
        security) fallback_topics+=(security-engineering) ;;
        research) fallback_topics+=(technical-research) ;;
        writing) fallback_topics+=(technical-writing) ;;
        workflow) fallback_topics+=(team-workflow) ;;
        product) fallback_topics+=(product-development) ;;
        general) fallback_topics+=(general-practice) ;;
    esac

    case "$skill_type" in
        technique) fallback_topics+=(execution-patterns) ;;
        pattern) fallback_topics+=(thinking-frameworks) ;;
        reference) fallback_topics+=(reference-material) ;;
        discipline) fallback_topics+=(operating-rules) ;;
    esac

    if [[ "$template_mode" == "knowledge-hybrid" ]]; then
        anchor_topics+=(knowledge-management)
        anchor_topics+=(agent-workflows)
    fi

    if [[ ${#anchor_topics[@]} -gt 0 ]]; then
        printf '%s\n' "${anchor_topics[@]}" | awk 'NF && !seen[$0]++' | awk 'NR<=4' | paste -sd ',' -
    else
        printf '%s\n' "${fallback_topics[@]}" | awk 'NF && !seen[$0]++' | awk 'NR<=3' | paste -sd ',' -
    fi
}

confirm_generated_list() {
    local label="$1"
    local suggestions="$2"
    local final_value="$suggestions"
    local choice custom

    while true; do
        echo "$label suggestion: $final_value" >&2
        echo "  1) Accept suggestion" >&2
        echo "  2) Edit manually" >&2
        echo -n "Choice (1-2, default 1): " >&2
        read -r choice
        choice="${choice:-1}"

        case "$choice" in
            1)
                if [[ -n "$final_value" ]]; then
                    echo "$final_value"
                    return 0
                fi
                print_warning "$label cannot be empty"
                ;;
            2)
                custom=$(get_metadata_list "Enter $label manually (comma-separated)")
                if [[ -n "$custom" ]]; then
                    final_value="$custom"
                else
                    print_warning "$label cannot be empty"
                fi
                ;;
            *) print_warning "Please enter 1-2" ;;
        esac
    done
}

get_non_goals() {
    local first second
    echo -n "Enter one non-goal (optional, press Enter to skip): " >&2
    read -r first
    if [[ -z "$first" ]]; then
        echo ""
        return 0
    fi

    echo -n "Enter a second non-goal (optional, press Enter to skip): " >&2
    read -r second

    if [[ -n "$second" ]]; then
        printf '%s|%s\n' "$first" "$second"
    else
        printf '%s\n' "$first"
    fi
}

get_maturity() {
    echo "Select skill maturity:" >&2
    echo "  1) draft      - Early idea, needs more shaping" >&2
    echo "  2) alpha      - Experimental but usable" >&2
    echo "  3) beta       - Tested and mostly stable" >&2
    echo "  4) stable     - Recommended for regular use" >&2
    echo "  5) deprecated - Kept for reference only" >&2

    while true; do
        echo -n "Choice (1-5, default 1): " >&2
        read -r choice
        choice="${choice:-1}"
        case "$choice" in
            1) echo "draft"; return 0 ;;
            2) echo "alpha"; return 0 ;;
            3) echo "beta"; return 0 ;;
            4) echo "stable"; return 0 ;;
            5) echo "deprecated"; return 0 ;;
            *) print_warning "Please enter 1-5" ;;
        esac
    done
}

get_skill_version() {
    local version
    while true; do
        echo -n "Enter skill version (default 0.1.0): " >&2
        read -r version
        version="${version:-0.1.0}"

        if [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-][A-Za-z0-9.-]+)?$ ]]; then
            echo "$version"
            return 0
        fi

        print_warning "Version must look like semver (example: 0.1.0 or 1.0.0-alpha)"
    done
}

get_last_verified() {
    local default_date verified
    default_date=$(date +%F)
    while true; do
        echo -n "Enter last verified date (YYYY-MM-DD, default $default_date): " >&2
        read -r verified
        verified="${verified:-$default_date}"

        if [[ "$verified" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
            echo "$verified"
            return 0
        fi

        print_warning "Date must use YYYY-MM-DD format"
    done
}

get_command_namespace() {
    local default_namespace="$1"
    local namespace
    while true; do
        echo -n "Enter command namespace (default $default_namespace): " >&2
        read -r namespace
        namespace="${namespace:-$default_namespace}"

        if validate_command_namespace "$namespace"; then
            echo "$namespace"
            return 0
        fi
    done
}

get_data_dir_contract() {
    local default_contract="$1"
    local contract
    while true; do
        echo -n "Enter data-dir contract (default $default_contract): " >&2
        read -r contract
        contract="${contract:-$default_contract}"

        if validate_data_dir_contract "$contract"; then
            echo "$contract"
            return 0
        fi
    done
}

write_toml_array() {
    local file_path="$1"
    local key="$2"
    local values="$3"
    local delimiter="${4:-,}"
    local rendered=""
    local item

    [[ -z "$values" ]] && return 0

    IFS="$delimiter" read -ra items <<< "$values"
    for item in "${items[@]}"; do
        item=$(printf '%s' "$item" | sed 's/^ *//; s/ *$//')
        [[ -z "$item" ]] && continue
        if [[ -n "$rendered" ]]; then
            rendered+=", "
        fi
        rendered+="\"$item\""
    done

    [[ -n "$rendered" ]] && printf '%s = [%s]\n' "$key" "$rendered" >> "$file_path"
}

write_yaml_list() {
    local file_path="$1"
    local key="$2"
    local values="$3"
    local delimiter="${4:-,}"
    local item

    [[ -z "$values" ]] && return 0

    echo "$key:" >> "$file_path"
    IFS="$delimiter" read -ra items <<< "$values"
    for item in "${items[@]}"; do
        item=$(printf '%s' "$item" | sed 's/^ *//; s/ *$//')
        [[ -n "$item" ]] && echo "  - $item" >> "$file_path"
    done
}

ask_yes_no() {
    local question="$1"
    local default="${2:-n}"
    local prompt
    if [[ "$default" =~ ^[Yy]$ ]]; then
        prompt="[Y/n]"
    else
        prompt="[y/N]"
    fi
    echo -n "$question $prompt: " >&2
    read -r answer
    answer="${answer:-$default}"
    [[ "$answer" =~ ^[Yy]$ ]]
}

generate_install_script() {
    local project_name="$1"
    local skill_name="$2"

    cat > "$SKILLS_DEV_DIR/$project_name/install.sh" << 'EOF'
#!/bin/bash
#
# install.sh - Install skill to ~/.config/opencode/skills
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_NAME="SKILL_NAME_PLACEHOLDER"
TARGET_DIR="$HOME/.config/opencode/skills/$SKILL_NAME"

echo "Installing skill: $SKILL_NAME"

mkdir -p "$TARGET_DIR"
cp "$SCRIPT_DIR/SKILL.toml" "$TARGET_DIR/"
cp "$SCRIPT_DIR/SKILL.md" "$TARGET_DIR/"

for dir_name in supporting commands scripts templates docs; do
    if [[ -d "$SCRIPT_DIR/$dir_name" ]]; then
        mkdir -p "$TARGET_DIR/$dir_name"
        cp -R "$SCRIPT_DIR/$dir_name/." "$TARGET_DIR/$dir_name/"
    fi
done

if [[ -d "$TARGET_DIR/scripts" ]]; then
    find "$TARGET_DIR/scripts" -type f -name "*.sh" -exec chmod +x {} \;
fi

echo "✓ Skill installed to: $TARGET_DIR"
echo ""
echo "To verify installation:"
echo "  ls -la ~/.config/opencode/skills/$SKILL_NAME/"
EOF

    sed -i "s/SKILL_NAME_PLACEHOLDER/$skill_name/g" "$SKILLS_DEV_DIR/$project_name/install.sh"
    chmod +x "$SKILLS_DEV_DIR/$project_name/install.sh"
}

generate_uninstall_script() {
    local project_name="$1"
    local skill_name="$2"

    cat > "$SKILLS_DEV_DIR/$project_name/uninstall.sh" << 'EOF'
#!/bin/bash
#
# uninstall.sh - Remove skill from ~/.config/opencode/skills
#

set -e

SKILL_NAME="SKILL_NAME_PLACEHOLDER"
TARGET_DIR="$HOME/.config/opencode/skills/$SKILL_NAME"

if [[ ! -d "$TARGET_DIR" ]]; then
    echo "Skill not installed: $SKILL_NAME"
    exit 0
fi

echo "Removing skill: $SKILL_NAME"
rm -rf "$TARGET_DIR"
echo "✓ Skill uninstalled from: $TARGET_DIR"
EOF

    sed -i "s/SKILL_NAME_PLACEHOLDER/$skill_name/g" "$SKILLS_DEV_DIR/$project_name/uninstall.sh"
    chmod +x "$SKILLS_DEV_DIR/$project_name/uninstall.sh"
}

generate_skill_toml() {
    local project_dir="$1"
    local skill_name="$2"
    local description="$3"
    local skill_type="$4"
    local category="$5"
    local boundary="$6"
    local tags="$7"
    local topics="$8"
    local non_goals="$9"
    local maturity="${10}"
    local skill_version="${11}"
    local last_verified="${12}"
    local template_mode="${13}"
    local command_namespace="${14}"
    local data_dir_contract="${15}"

    cat > "$project_dir/SKILL.toml" << EOF
manifest_version = "$MANIFEST_VERSION"

[skill]
name = "$skill_name"
version = "$skill_version"
description = "$description"
type = "$skill_type"
category = "$category"
boundary = "$boundary"
maturity = "$maturity"
last_verified = "$last_verified"
EOF

    write_toml_array "$project_dir/SKILL.toml" "tags" "$tags"
    write_toml_array "$project_dir/SKILL.toml" "topics" "$topics"
    write_toml_array "$project_dir/SKILL.toml" "non_goals" "$non_goals" "|"

    cat >> "$project_dir/SKILL.toml" << EOF

[source]
repository = "https://github.com/your-org/opencode-skill-$skill_name"
license = "MIT"

[compat]
min_opencode_version = "0.1.0"
EOF

    if [[ "$template_mode" == "knowledge-hybrid" ]]; then
        cat >> "$project_dir/SKILL.toml" << EOF

[hybrid]
enabled = true
mode = "knowledge-hybrid"
command_namespace = "$command_namespace"
generated_commands = ["$command_namespace-save", "$command_namespace-search", "$command_namespace-load"]
data_dir_contract = "$data_dir_contract"

[knowledge]
enabled = true
storage_format = "markdown"
data_dir = "$data_dir_contract"
default_index = "index.md"
templates_dir = "templates"
commands_dir = "commands"
scripts_dir = "scripts"
EOF
    fi
}

generate_skill_md() {
    local project_dir="$1"
    local skill_name="$2"
    local description="$3"
    local skill_type="$4"
    local category="$5"
    local boundary="$6"
    local tags="$7"
    local topics="$8"
    local non_goals="$9"
    local maturity="${10}"
    local skill_version="${11}"
    local last_verified="${12}"
    local template_mode="${13}"
    local command_namespace="${14}"
    local data_dir_contract="${15}"
    local title_name

    title_name=$(echo "$skill_name" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2));}1')

    cat > "$project_dir/SKILL.md" << EOF
---
name: $skill_name
description: $description
version: $skill_version
manifest_version: $MANIFEST_VERSION
template_mode: $template_mode
EOF

    write_yaml_list "$project_dir/SKILL.md" "tags" "$tags"
    write_yaml_list "$project_dir/SKILL.md" "topics" "$topics"
    write_yaml_list "$project_dir/SKILL.md" "non_goals" "$non_goals" "|"

    cat >> "$project_dir/SKILL.md" << EOF
---

# $title_name

## Overview
Brief description of what this skill provides and its core principle.

> Canonical metadata lives in \`SKILL.toml\`. Keep this document focused on instructional content.

## When to Use
- Specific situation 1
- Specific situation 2
- Specific situation 3

**When NOT to use:**
- Situation where this doesn't apply

## Boundary
$boundary

## Metadata Snapshot
- Type: $skill_type
- Category: $category
- Template Mode: $template_mode
- Maturity: $maturity
- Last Verified: $last_verified

## Non-Goals
- Explicitly list what this skill does not try to solve
- Remove anything that would make the skill too broad

EOF

    if [[ "$template_mode" == "knowledge-hybrid" ]]; then
        cat >> "$project_dir/SKILL.md" << EOF
## Hybrid Contract

This project is a knowledge-hybrid skill. In addition to the core skill instructions, it defines a small namespaced command surface and a knowledge storage contract.

- Command Namespace: \`$command_namespace\`
- Save Command: \`/$command_namespace-save\`
- Search Command: \`/$command_namespace-search\`
- Load Command: \`/$command_namespace-load\`
- Data Directory Contract: \`$data_dir_contract\`

The generated \`commands/\`, \`scripts/\`, and \`templates/\` directories are part of the public interface for this hybrid package.

## Knowledge Workflow
1. Save structured notes or artifacts into the contracted data directory.
2. Search those notes by topic, keyword, or filename.
3. Load the most relevant note back into the working context.
4. Refine the templates and command docs to match the domain.

## Hybrid Assets
- \`commands/\` contains command-facing docs for save/search/load
- \`scripts/\` contains helper shell entrypoints
- \`templates/\` contains starter knowledge document templates

EOF
    fi

    case "$skill_type" in
        technique)
            cat >> "$project_dir/SKILL.md" << 'EOF'
## Core Technique

### Step-by-Step
1. First step description
2. Second step description
3. Third step description

### Example
```bash
# Example code showing the technique
```

EOF
            ;;
        pattern)
            cat >> "$project_dir/SKILL.md" << 'EOF'
## The Pattern

### Mental Model
Description of how to think about this problem.

### Before/After Comparison
**Before (problem):**
```bash
# Code showing the problem
```

**After (solution):**
```bash
# Code showing the solution
```

EOF
            ;;
        reference)
            cat >> "$project_dir/SKILL.md" << 'EOF'
## Quick Reference

| Command/Option | Description | Example |
|---------------|-------------|---------|
| `command` | What it does | `command --flag` |

## Common Operations

### Operation 1
```bash
# Code example
```

EOF
            ;;
        discipline)
            cat >> "$project_dir/SKILL.md" << 'EOF'
## The Rule

Clear statement of what must be done.

## Red Flags - STOP and Reconsider

- Warning sign 1
- Warning sign 2
- Warning sign 3

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Reason to skip" | Why that's wrong |

EOF
            ;;
    esac

    cat >> "$project_dir/SKILL.md" << 'EOF'
## Common Mistakes

### Mistake 1: Brief description
**Problem:** What goes wrong
**Fix:** How to fix it

### Mistake 2: Brief description
**Problem:** What goes wrong
**Fix:** How to fix it

## See Also

- Related skill 1
- Related skill 2
EOF

    if [[ "$template_mode" == "knowledge-hybrid" ]]; then
        cat >> "$project_dir/SKILL.md" << EOF

## Hybrid Maintenance Notes
- Keep command docs aligned with the helper scripts
- Keep template examples compatible with the data-dir contract
- Update both \`SKILL.toml\` and the generated docs if the namespace changes
EOF
    fi
}

generate_hybrid_assets() {
    local project_dir="$1"
    local command_namespace="$2"
    local data_dir_contract="$3"

    mkdir -p "$project_dir/commands" "$project_dir/scripts" "$project_dir/templates"

    cat > "$project_dir/templates/knowledge-entry.md" << EOF
# Knowledge Entry Title

- Namespace: $command_namespace
- Created: YYYY-MM-DD
- Source:
- Tags:

## Summary
Short summary of the note or artifact.

## Details
Capture the important details here.

## Related
- Link related entries, tasks, or follow-up work.
EOF

    cat > "$project_dir/commands/${command_namespace}-save.md" << EOF
# /$command_namespace-save

Save a new knowledge artifact into the contracted data directory.

## Purpose
Use this command when you want to persist a durable note, decision, snippet, or research result for later retrieval.

## Data Contract
- Namespace: \`$command_namespace\`
- Data Directory: \`$data_dir_contract\`
- Default Template: \`templates/knowledge-entry.md\`

## Script
\`scripts/${command_namespace}-save.sh\`
EOF

    cat > "$project_dir/commands/${command_namespace}-search.md" << EOF
# /$command_namespace-search

Search previously saved knowledge artifacts within the contracted data directory.

## Purpose
Use this command when you need to find stored notes by keyword, filename, or topic before answering or implementing.

## Data Contract
- Namespace: \`$command_namespace\`
- Data Directory: \`$data_dir_contract\`

## Script
\`scripts/${command_namespace}-search.sh\`
EOF

    cat > "$project_dir/commands/${command_namespace}-load.md" << EOF
# /$command_namespace-load

Load a specific knowledge artifact back into working context.

## Purpose
Use this command when you already know the note you want, or after search has identified the best match.

## Data Contract
- Namespace: \`$command_namespace\`
- Data Directory: \`$data_dir_contract\`

## Script
\`scripts/${command_namespace}-load.sh\`
EOF

    cat > "$project_dir/scripts/${command_namespace}-save.sh" << 'EOF'
#!/bin/bash
set -e
NAMESPACE="COMMAND_NAMESPACE_PLACEHOLDER"
DATA_DIR_CONTRACT="DATA_DIR_CONTRACT_PLACEHOLDER"
TITLE="${1:-untitled-note}"
TARGET_ROOT="${OPENCODE_SKILL_DATA_DIR:-$DATA_DIR_CONTRACT}"
SLUG=$(printf '%s' "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g; s/-\{2,\}/-/g; s/^-//; s/-$//')
TARGET_FILE="$TARGET_ROOT/${SLUG:-untitled-note}.md"
mkdir -p "$TARGET_ROOT"
if [[ -f "$TARGET_FILE" ]]; then
    echo "Knowledge entry already exists: $TARGET_FILE"
    exit 1
fi
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/../templates/knowledge-entry.md" ]]; then
    cp "$(dirname "${BASH_SOURCE[0]}")/../templates/knowledge-entry.md" "$TARGET_FILE"
else
    cat > "$TARGET_FILE" <<ENTRY
# ${TITLE}

## Summary

## Details

## Related
ENTRY
fi
echo "Created knowledge entry for namespace '$NAMESPACE': $TARGET_FILE"
EOF
    sed -i "s/COMMAND_NAMESPACE_PLACEHOLDER/$command_namespace/g" "$project_dir/scripts/${command_namespace}-save.sh"
    sed -i "s|DATA_DIR_CONTRACT_PLACEHOLDER|$data_dir_contract|g" "$project_dir/scripts/${command_namespace}-save.sh"
    chmod +x "$project_dir/scripts/${command_namespace}-save.sh"

    cat > "$project_dir/scripts/${command_namespace}-search.sh" << 'EOF'
#!/bin/bash
set -e
DATA_DIR_CONTRACT="DATA_DIR_CONTRACT_PLACEHOLDER"
QUERY="${1:-}"
TARGET_ROOT="${OPENCODE_SKILL_DATA_DIR:-$DATA_DIR_CONTRACT}"
if [[ -z "$QUERY" ]]; then
    echo "Usage: $(basename "$0") <query>"
    exit 1
fi
if [[ ! -d "$TARGET_ROOT" ]]; then
    echo "Knowledge directory does not exist yet: $TARGET_ROOT"
    exit 0
fi
grep -Rin --exclude-dir='.git' -- "$QUERY" "$TARGET_ROOT" || true
EOF
    sed -i "s|DATA_DIR_CONTRACT_PLACEHOLDER|$data_dir_contract|g" "$project_dir/scripts/${command_namespace}-search.sh"
    chmod +x "$project_dir/scripts/${command_namespace}-search.sh"

    cat > "$project_dir/scripts/${command_namespace}-load.sh" << 'EOF'
#!/bin/bash
set -e
DATA_DIR_CONTRACT="DATA_DIR_CONTRACT_PLACEHOLDER"
TARGET="${1:-}"
TARGET_ROOT="${OPENCODE_SKILL_DATA_DIR:-$DATA_DIR_CONTRACT}"
if [[ -z "$TARGET" ]]; then
    echo "Usage: $(basename "$0") <file-or-relative-path>"
    exit 1
fi
if [[ -f "$TARGET" ]]; then
    cat "$TARGET"
    exit 0
fi
if [[ -f "$TARGET_ROOT/$TARGET" ]]; then
    cat "$TARGET_ROOT/$TARGET"
    exit 0
fi
if [[ -f "$TARGET_ROOT/$TARGET.md" ]]; then
    cat "$TARGET_ROOT/$TARGET.md"
    exit 0
fi
echo "Knowledge entry not found: $TARGET"
exit 1
EOF
    sed -i "s|DATA_DIR_CONTRACT_PLACEHOLDER|$data_dir_contract|g" "$project_dir/scripts/${command_namespace}-load.sh"
    chmod +x "$project_dir/scripts/${command_namespace}-load.sh"

    print_success "Created hybrid commands, scripts, and templates"
}

generate_readme() {
    local project_dir="$1"
    local project_name="$2"
    local skill_name="$3"
    local description="$4"
    local skill_type="$5"
    local category="$6"
    local boundary="$7"
    local maturity="$8"
    local template_mode="$9"
    local command_namespace="${10}"
    local data_dir_contract="${11}"

    cat > "$project_dir/README.md" << EOF
# $project_name

$description

## Metadata Summary

- **Type:** $skill_type
- **Category:** $category
- **Boundary:** $boundary
- **Template Mode:** $template_mode
- **Maturity:** $maturity

## Installation

\`\`\`bash
./install.sh
\`\`\`

This will install the skill to \`~/.config/opencode/skills/$skill_name/\`

The generated project also includes a canonical \`SKILL.toml\` manifest for package-manager tooling.

## Uninstallation

\`\`\`bash
./uninstall.sh
\`\`\`

## Project Structure

\`\`\`
$project_name/
├── SKILL.toml            # Canonical machine-readable manifest
├── SKILL.md              # Main skill file (installed to ~/.config/opencode/skills/)
├── install.sh            # Installation script
├── uninstall.sh          # Uninstallation script
├── README.md             # This file
EOF

    if [[ "$template_mode" == "knowledge-hybrid" ]]; then
        cat >> "$project_dir/README.md" << EOF
├── commands/             # Namespaced save/search/load command docs
├── scripts/              # Helper shell scripts for hybrid workflow
├── templates/            # Starter knowledge-entry templates
EOF
    fi

    cat >> "$project_dir/README.md" << 'EOF'
└── .git/                 # Version control
```

## Development

This skill follows the OpenCode skill development pattern:
- Source files are managed in this repository
- `SKILL.toml` is the canonical metadata source
- `SKILL.md` contains the human/agent-readable instructions
- Supporting files can be included in optional package directories

EOF

    if [[ "$template_mode" == "knowledge-hybrid" ]]; then
        cat >> "$project_dir/README.md" << EOF
## Hybrid Mode

This project was generated in **knowledge-hybrid** mode.

### Hybrid Contract
- **Command Namespace:** \`$command_namespace\`
- **Commands:** \`/$command_namespace-save\`, \`/$command_namespace-search\`, \`/$command_namespace-load\`
- **Data Directory Contract:** \`$data_dir_contract\`

### Generated Hybrid Assets
- \`commands/${command_namespace}-save.md\`
- \`commands/${command_namespace}-search.md\`
- \`commands/${command_namespace}-load.md\`
- \`scripts/${command_namespace}-save.sh\`
- \`scripts/${command_namespace}-search.sh\`
- \`scripts/${command_namespace}-load.sh\`
- \`templates/knowledge-entry.md\`

The generated install script will copy \`commands/\`, \`scripts/\`, \`templates/\`, and \`docs/\` when those directories are present.

EOF
    fi

    cat >> "$project_dir/README.md" << 'EOF'
## License

MIT
EOF
}

init_git() {
    local project_dir="$1"
    local skill_name="$2"
    cd "$project_dir"
    git init
    git add .
    git commit -m "Initial commit: $skill_name skill"
    print_success "Git repository initialized"
}

main() {
    print_header "OpenCode Skill Creator"

    if [[ ! -d "$SKILLS_DEV_DIR" ]]; then
        echo "Creating skills development directory: $SKILLS_DEV_DIR"
        mkdir -p "$SKILLS_DEV_DIR"
    fi

    local skill_name
    skill_name=$(get_skill_name "$1") || exit 1

    local project_name="${SKILL_PREFIX}${skill_name}"
    local project_dir="$SKILLS_DEV_DIR/$project_name"

    if [[ -d "$project_dir" ]]; then
        print_error "Project already exists: $project_dir"
        if ! ask_yes_no "Overwrite existing project?"; then
            echo "Aborted."
            exit 1
        fi
        rm -rf "$project_dir"
    fi

    local description
    description=$(get_description)

    local template_mode
    template_mode=$(get_template_mode)

    local skill_type
    skill_type=$(get_skill_type)

    local category
    category=$(get_category)

    local boundary
    boundary=$(get_boundary)

    local tags
    tags=$(confirm_generated_list "Tags" "$(build_tag_suggestions "$skill_name" "$category" "$description" "$boundary" "$template_mode")")

    local topics
    topics=$(confirm_generated_list "Topics" "$(build_topic_suggestions "$category" "$skill_type" "$boundary" "$description" "$skill_name" "$template_mode")")

    local non_goals
    non_goals=$(get_non_goals)

    local maturity
    maturity=$(get_maturity)

    local skill_version
    skill_version=$(get_skill_version)

    local last_verified
    last_verified=$(get_last_verified)

    local command_namespace=""
    local data_dir_contract=""
    if [[ "$template_mode" == "knowledge-hybrid" ]]; then
        command_namespace=$(get_command_namespace "$skill_name")
        data_dir_contract=$(get_data_dir_contract "${XDG_DATA_HOME:-$HOME/.local/share}/opencode/$command_namespace")
    fi

    print_header "Creating Project: $project_name"
    mkdir -p "$project_dir"
    echo "Generating files..."

    generate_skill_toml "$project_dir" "$skill_name" "$description" "$skill_type" "$category" "$boundary" "$tags" "$topics" "$non_goals" "$maturity" "$skill_version" "$last_verified" "$template_mode" "$command_namespace" "$data_dir_contract"
    print_success "Created SKILL.toml"

    generate_skill_md "$project_dir" "$skill_name" "$description" "$skill_type" "$category" "$boundary" "$tags" "$topics" "$non_goals" "$maturity" "$skill_version" "$last_verified" "$template_mode" "$command_namespace" "$data_dir_contract"
    print_success "Created SKILL.md"

    if [[ "$template_mode" == "knowledge-hybrid" ]]; then
        generate_hybrid_assets "$project_dir" "$command_namespace" "$data_dir_contract"
    fi

    generate_install_script "$project_name" "$skill_name"
    print_success "Created install.sh"

    generate_uninstall_script "$project_name" "$skill_name"
    print_success "Created uninstall.sh"

    generate_readme "$project_dir" "$project_name" "$skill_name" "$description" "$skill_type" "$category" "$boundary" "$maturity" "$template_mode" "$command_namespace" "$data_dir_contract"
    print_success "Created README.md"

    if ask_yes_no "Initialize git repository?" "y"; then
        init_git "$project_dir" "$skill_name"
    fi

    print_header "Project Created Successfully!"
    echo "Location: $project_dir"
    echo ""
    echo "Next steps:"
    echo "  1. cd $project_dir"
    echo "  2. Review SKILL.toml metadata and edit SKILL.md with your content"
    if [[ "$template_mode" == "knowledge-hybrid" ]]; then
        echo "  3. Review commands/, scripts/, and templates/ for your hybrid workflow"
        echo "  4. Run ./install.sh to install the hybrid package"
        echo ""
        echo "Hybrid contract:"
        echo "  - Namespace: $command_namespace"
        echo "  - Data directory: $data_dir_contract"
    else
        echo "  3. Run ./install.sh to install the skill"
    fi
    echo ""
    echo "To install the skill:"
    echo "  cd $project_dir && ./install.sh"
    echo ""

    if command -v code &> /dev/null && ask_yes_no "Open in VS Code?" "n"; then
        code "$project_dir"
    fi
}

main "$@"
