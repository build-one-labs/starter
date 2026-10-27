# AGENTS.md

Instructions for coding agents working in this repository — a business
application built on the Build.One framework.

`CLAUDE.md` in this directory is the primary, maintained guide, and it goes
deeper than this file on every topic below. **Read it.** This file exists because
some agents (Codex among them) look for `AGENTS.md` rather than `CLAUDE.md`; it
carries the rules that are expensive to get wrong, and defers the rest.

## Critical rules

### Blueprint JSON files

- **Always** use the B1 MCP server (`B1_Blueprint`) to query and change blueprints — screens, forms, grids, data sources, menus and every other blueprint object.
- **Never** create, edit or delete the blueprint JSON files under `src/data/repository/` and `src/data/base/` by hand. They are the git-versioned export of the blueprint database: the running application reads the database, not these files, so a hand edit does not show up in the app and is lost at the object's next export.
- If a B1 MCP tool answers "ACCESS DENIED", stop and report it to the user; do not work around it by editing the files.
- `CLAUDE.md` carries this rule word for word; change both together.

### Prefer b1 object types over native Vue components

- When building UI, **use an existing b1 object type whenever one fits the requirement** — `b1_grid` for lists and tables, `b1_form` for data entry, `b1_card_view`, `b1_chart`, `b1_tree_grid`, `b1_scheduler`, … — and do **not** create a native Vue component (`b1_native_component`, backed by a hand-written `.vue` file) for the job instead. Object types are declarative, bound to data through links, editable in the designer and through the B1 MCP tools, and maintained with the framework; a native component is none of these.
- Look for the fitting type before writing any Vue: `search_blueprint` / `search_object_types` for the need, `describe_object_type` for what a type does, then the build flow (`create_data_layer`, `create_from_template`, `compose`, `set_field` — see `node_modules/@buildone/swat-cli/knowledge/blueprint_dsl/build-flow.md`). Configuring an existing type (its attributes, a template, `compose`) counts as "fits".
- A `b1_native_component` is acceptable **only with a good reason**, which is one of exactly two:
  1. **no suitable b1 object type exists** for the requirement, or
  2. **the user experience with the b1 object type would be clearly worse** than with a native component.
- The usual good reason is a **dashboard screen**: a custom layout of KPI tiles, summaries and visualisations that no object type composes the way the screen needs. A native component is **not** a replacement for an existing b1 object type — never swap a screen's `b1_grid` (or `b1_form`, …) for a hand-written Vue table or form. When the object type falls short, configure it (columns, templates, attributes), or extend the object type itself.
- When you do create one, state which of the two applies, and why, in the conversation and in the pull request description, so a reviewer can check it. "Writing the Vue was quicker" is not a reason. App help pages built from the `Help*` kit (`help-screens.md`) are native components by design and need no further justification.
- `CLAUDE.md` carries this rule word for word; change both together.

### Temporary files

- Store temporary files (scratch scripts, intermediate results, downloads, generated output that does not belong in the project) in the workspace `tmp/` directory at the repository root, e.g. `/workspaces/<repo-name>/tmp` — for the customer repo `sass-marketplace` that is `/workspaces/sass-marketplace/tmp`.
- **Never** write them to the system `/tmp` or anywhere else in the source tree. `tmp/` is git-ignored, so nothing in it is committed.
- Use one subdirectory per task (e.g. `tmp/<task-name>/`); `tmp/workspace/` belongs to the workspace tooling. Remove files you no longer need when the task is done.
- `CLAUDE.md` carries this rule word for word; change both together.

## Repository layout

| Workspace | |
|---|---|
| `src/app-server-ts/` | NestJS backend API (Drizzle ORM, server actions) |
| `src/web-app/` | Nuxt 3 frontend (PrimeVue, extends `@buildone/web-framework-layer`) |
| `src/data/` | Data definitions for the Build.One SmartFramework |

Development commands, architecture, CI/CD, migrations and environment variables
are documented in `CLAUDE.md`.

## Knowledge base

Detailed framework documentation lives in the published CLI package. Read the
relevant `CLAUDE.md` index first — each lists its files, a reading order, and the
key concepts:

| Topic | Start here |
|---|---|
| Navigation and overview | `node_modules/@buildone/swat-cli/knowledge/CLAUDE.md` |
| Architecture, DevOps, CLI, deployment | `node_modules/@buildone/swat-cli/knowledge/architecture_info/CLAUDE.md` |
| Blueprint DSL — screens, forms, grids, fieldsets, data binding | `node_modules/@buildone/swat-cli/knowledge/blueprint_dsl/CLAUDE.md` |
