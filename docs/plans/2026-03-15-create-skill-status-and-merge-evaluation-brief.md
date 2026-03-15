# opencode-skill-create Status and Merge Evaluation Brief

**Date:** 2026-03-15  
**Project:** `/home/lotus/Project/Skills/opencode-skill-create`  
**Related Project:** `/home/lotus/Project/Skills/opencode-skill-management`  
**Purpose:** Hand-off brief for a future session to evaluate whether the two projects should remain separate, become a shared workspace, or merge into one product.

---

## 1. Executive Summary

`opencode-skill-create` has moved beyond a simple shell wizard that creates skill-only packages.

It now supports two package modes:

1. `skill-only`
2. `knowledge-hybrid`

The `knowledge-hybrid` mode generates a first-stage workflow-capable package that includes:

- `SKILL.toml`
- `SKILL.md`
- `commands/`
- `scripts/`
- `templates/`
- install / uninstall scripts

This means the project is no longer just a skill scaffold. It is becoming a **package authoring tool** for OpenCode capabilities.

At the same time, `opencode-skill-management` is clearly evolving as a **package manager / installer / sync engine** for these kinds of packages.

The central strategic question is no longer “can these tools work together?” but:

> Should they remain separate products with a shared contract, or converge into a shared codebase / workspace / CLI?

Current recommendation:

> **Do not directly merge the two projects yet.**
> First stabilize the shared manifest and hybrid-package contract, then reassess whether a Rust workspace or shared crate model is justified.

---

## 2. Current State of `opencode-skill-create`

### 2.1 Original role

The project started as a shell-based wizard for generating standard OpenCode skills with:

- `SKILL.toml`
- `SKILL.md`
- `install.sh`
- `uninstall.sh`
- `README.md`

This was a good fit for shell when the problem was mostly:

- interactive prompts
- file creation
- simple templating

### 2.2 Current role

The project now does more than create basic skills.

It supports:

- template mode selection
- manifest-first package generation
- hybrid metadata generation
- command namespace generation
- data-dir contract generation
- command/script/template scaffolding
- hybrid runtime installation layout

This moves it closer to a **capability package authoring tool**.

### 2.3 Implemented package modes

#### `skill-only`

Generates a classic OpenCode skill package.

#### `knowledge-hybrid`

Generates a first-stage hybrid package with:

- namespaced command docs for `save/search/load`
- shell scripts for those commands
- a starter knowledge template
- hybrid and knowledge metadata in `SKILL.toml`

---

## 3. What Was Implemented in This Session

### 3.1 Generator upgrades

`create-skill.sh` was upgraded to:

- support `skill-only` and `knowledge-hybrid`
- prompt for `command_namespace` in hybrid mode
- prompt for `data_dir_contract` in hybrid mode
- generate `[hybrid]` and `[knowledge]` blocks in generated manifests
- generate hybrid assets under `commands/`, `scripts/`, and `templates/`

### 3.2 Top-level project alignment

The repository itself now has a top-level `SKILL.toml`, making the project more consistent with its own manifest-first philosophy.

### 3.3 Install behavior improvements

Generated `install.sh` scripts now copy more than just the skill files. They also copy optional runtime directories such as:

- `supporting/`
- `commands/`
- `scripts/`
- `templates/`
- `docs/`

This makes hybrid packages installable as runtime-capable artifacts.

### 3.4 Documentation updates

The following files were updated to reflect the new model:

- `README.md`
- `SKILL.md`
- `CLAUDE.md`

These now describe:

- the two template modes
- hybrid metadata
- hybrid runtime assets
- the external data-dir contract idea

### 3.5 Design and contract docs created

The following planning documents were added during this session:

- `docs/plans/2026-03-15-knowledge-hybrid-design.md`
- `docs/plans/2026-03-15-hybrid-compatibility-contract.md`

These documents contain the rationale, structure, and integration contract for hybrid packages.

---

## 4. Verified Behavior in This Session

This is important: the project was not only edited, it was actually tested.

### 4.1 Generator syntax check

`create-skill.sh` was syntax-checked with `bash -n` and passed.

### 4.2 `skill-only` generation was smoke-tested

A real `skill-only` package was generated successfully.

Observed generated structure:

- `SKILL.toml`
- `SKILL.md`
- `install.sh`
- `uninstall.sh`
- `README.md`

### 4.3 `knowledge-hybrid` generation was smoke-tested

A real hybrid package was generated successfully.

Observed generated structure:

- `SKILL.toml`
- `SKILL.md`
- `commands/`
- `scripts/`
- `templates/`
- `install.sh`
- `uninstall.sh`
- `README.md`

### 4.4 Hybrid manifest output was verified

Generated manifests included:

- `[hybrid]`
- `[knowledge]`
- `command_namespace`
- `generated_commands`
- `data_dir_contract`

### 4.5 Scaffold runtime behavior was verified

Generated hybrid scripts were executed successfully:

- `research-save.sh` created a note file
- `research-search.sh` found content in the saved note
- `research-load.sh` loaded the note content
- generated `install.sh` installed runtime assets
- generated `uninstall.sh` removed the installed package

This means the first-stage hybrid package is not merely theoretical. It is a working prototype.

---

## 5. Architectural Interpretation of the Current State

### 5.1 What the project is now

`opencode-skill-create` is no longer just a “create skill” script.

It is becoming a:

> **package authoring / scaffolding tool for OpenCode capability packages**

### 5.2 What it is not yet

It is not yet:

- a package manager
- a registry
- an installer of record
- a unified runtime manager
- a workflow-first package generator

### 5.3 Why this matters

This means the product is crossing a boundary.

It is moving from:

- simple file scaffold generation

to:

- authoring structured, installable, workflow-capable packages

That change has implications for both architecture and language choice.

---

## 6. Language and Architecture Pressure

### 6.1 Why shell was originally reasonable

Shell was a sensible starting point because the original problem was mostly:

- collecting prompt input
- writing a few files
- simple project bootstrapping

### 6.2 Why shell is starting to strain

The project is now dealing with:

- multiple template modes
- branching generation logic
- structured metadata
- hybrid-specific fields
- nested runtime assets
- install layout rules
- compatibility contracts with another tool

That means the generator is beginning to look less like a shell script and more like a small compiler / renderer for package structures.

### 6.3 Current judgment

The project has reached the point where shell is no longer an ideal long-term home for the core logic.

Recommended direction:

> **Do not immediately rewrite everything.**
> Instead, treat this as a signal to gradually move toward a Rust core while preserving a lightweight shell or CLI entry if useful.

---

## 7. Relationship to `opencode-skill-management`

### 7.1 What `opencode-skill-management` is

`opencode-skill-management` is not another scaffold generator.

It is a Rust-based package manager / installer / sync engine that already handles:

- skill config
- lockfiles
- content-addressable storage
- installation
- sync to assistant runtimes
- metadata-aware commands like list/info/doctor/outdated

### 7.2 Natural division of responsibility

At this moment, the cleanest product boundary is:

#### `opencode-skill-create`
- authoring
- scaffolding
- package layout generation
- template evolution

#### `opencode-skill-management`
- install
- sync
- validation
- registry / dependency management
- runtime diagnostics

This is a healthy split.

### 7.3 Why they feel related

They are increasingly coupled because both now revolve around the same concepts:

- `SKILL.toml`
- package metadata
- installable runtime assets
- hybrid packages
- future package ecosystem conventions

So the question is not whether they are related. They clearly are.

The question is whether they should be merged at the repository/product level or coordinated through a shared contract and later shared code.

---

## 8. Current Recommendation on Merge Strategy

### 8.1 Recommendation

> **Do not directly merge the two projects yet.**

### 8.2 Why not merge yet

Because the two tools still operate at different product layers:

- authoring / scaffolding
- package management / installation / sync

If merged too early, there is a high risk of creating a confused “god tool” that mixes:

- scaffold generation
- package installation
- lockfile logic
- runtime sync
- registry concerns
- hybrid semantics

That would blur boundaries before the shared protocol is stable.

### 8.3 Better short-term strategy

Use this sequence instead:

1. stabilize the shared manifest contract
2. stabilize hybrid-package semantics
3. clarify command ownership and install ownership
4. move `opencode-skill-create` toward a Rust core if justified
5. then reassess monorepo / workspace / merge options

---

## 9. Recommended Shared Contract Before Any Merge

The following should be stabilized first:

### 9.1 Manifest contract

- base `SKILL.toml` schema
- `[hybrid]`
- `[knowledge]`
- compatibility fields

### 9.2 Command namespace contract

- `command_namespace`
- command naming pattern like `{namespace}-save`
- collision expectations

### 9.3 Data-dir contract

Mutable knowledge data must not depend on the installed runtime package path.

Preferred default direction:

```text
${XDG_DATA_HOME:-$HOME/.local/share}/opencode/<namespace>
```

### 9.4 Runtime package contract

Clearly distinguish:

- installable runtime assets
- mutable external knowledge state

### 9.5 Ownership contract

Clarify who owns:

- command exposure
- install logic
- package validation
- doctor/info/list behavior

---

## 10. Open Product Questions for the Next Session

The next session should explicitly evaluate these questions:

### 10.1 Merge questions

1. Should the projects stay as two repositories with a shared manifest contract?
2. Should they move into a monorepo / Rust workspace while remaining separate binaries?
3. Should they become a single unified CLI product?

### 10.2 Language questions

4. Should `opencode-skill-create` remain shell for one more phase?
5. Should it move to a “shell wrapper + Rust core” model?
6. Should it be fully rewritten in Rust?

### 10.3 Ownership questions

7. Is generated `install.sh` still a long-term product feature, or only a fallback/dev convenience?
8. Should `opencode-skill-management` become the installer of record for hybrid packages?
9. Should command shims eventually be owned by the package manager rather than generated scripts?

### 10.4 Package model questions

10. Should `opencode-skill-create` grow `command-only` mode?
11. Should it grow `workflow-pack` mode?
12. Is `knowledge-hybrid` only the first hybrid kind, or the beginning of a generic capability-package model?

---

## 11. Suggested Near-Term Features for `opencode-skill-create`

These are the most reasonable next steps if the project remains separate for now.

### Priority 1

1. **Real template extraction**
   - move more generated content out of `create-skill.sh` into actual `templates/`

2. **command-only mode**
   - support packages that are command-centric rather than skill-centric

3. **hybrid contract cleanup**
   - tighten generated README/SKILL/manifests around the new contract

### Priority 2

4. **workflow-pack exploration**
   - evaluate a first-class package mode for workflow-heavy scaffolds

5. **Rust core exploration**
   - model package generation as typed structs / enums rather than positional shell arguments

6. **better verification suite**
   - automate smoke tests for generated skill-only and hybrid packages

### Priority 3

7. **package-manager compatibility hardening**
   - continue shaping generated hybrid packages so they are easy for `opencode-skill-management` to understand later

---

## 12. Suggested Near-Term Features for Cross-Project Alignment

If the projects remain separate for now, the best alignment work is:

1. make `opencode-skill-management` tolerate and later understand `[hybrid]`
2. align command namespace rules
3. align data-dir contract rules
4. align install/runtime asset semantics
5. define whether shared crates or shared schemas are the long-term convergence model

---

## 13. My Current Strategic Judgment

If I had to compress the current state into a few sentences:

`opencode-skill-create` is now a valid first-stage package authoring tool, not just a skill wizard. It has already crossed the threshold where shell is becoming a strained long-term implementation language. It is closely related to `opencode-skill-management`, but not yet mature enough in shared contract and product boundaries to justify direct merger.

The strongest path right now is:

> **keep them separate, stabilize the shared contract, then revisit workspace/merge decisions once package semantics and ownership are clearer.**

---

## 14. Handoff Summary for the Next Session

The next session should treat this project as:

- a working first-stage hybrid-capable authoring tool
- a likely future Rust-core candidate
- a strong upstream companion to `opencode-skill-management`
- not yet ready for direct repository/product merger

The evaluation target is not merely “merge or not merge.”

It is:

> What is the right convergence path between package authoring and package management in this ecosystem?

Possible answers include:

- shared contract only
- shared Rust crates
- Rust workspace with two binaries
- full product merge

This document recommends beginning that evaluation from a **shared-contract-first** stance, not a merge-first stance.
