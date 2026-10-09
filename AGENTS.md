# AGENTS.md

Instructions for coding agents working in this repository — a business
application built on the Build.One framework.

`CLAUDE.md` in this directory is the primary, maintained guide, and it goes
deeper than this file on every topic below. **Read it.** This file exists because
some agents (Codex among them) look for `AGENTS.md` rather than `CLAUDE.md`; it
carries the rules that are expensive to get wrong, and defers the rest.

## Critical rules

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
