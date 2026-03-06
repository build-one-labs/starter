# Sync from Starter Template

Synchronize this project with the latest changes from the Build.One starter template repository (`build-one-labs/starter`).

## Trigger Phrases

Use this skill when the user says any of the following:
- "sync from template"
- "sync with template"
- "update from template"
- "pull template changes"
- "sync starter"

## Overview

Downstream apps created from the Build.One starter template diverge over time as project-specific code is added. This skill syncs template infrastructure updates (CI/CD, devcontainer, tooling, configs) into the project without overwriting project-specific files.

**Version detection:** The script reads the `@buildone/swat-cli` version from `package.json` (e.g., `24.3.0-VG.134`) and finds the matching commit in the template repo by its message pattern `Build.One <version> Starter App`. This is the "from" point. The "to" point is the latest commit on the template's develop branch (or a specified version).

## Your Task

### Step 1: Check Current Version

Read the current `@buildone/swat-cli` version from `package.json`:

```bash
node -e "console.log(require('./package.json').devDependencies['@buildone/swat-cli'])"
```

Report to the user what version they're currently on.

### Step 2: Preview Changes

Always start with a dry run so the user can review before applying:

```bash
.devcontainer/scripts/sync-from-template.sh --dry-run
```

This will:
- Clone the template repo
- Find the commit matching the current `@buildone/swat-cli` version
- Show commits in the range and files affected
- Display the patch without applying

Present to the user:
- Current version and target version
- The list of template commits since their version
- The files that will be changed
- Ask if they want to proceed, sync to a different version, or abort

### Step 3: Apply Changes

If the user approves, run the actual sync:

```bash
.devcontainer/scripts/sync-from-template.sh
```

If there are conflicts:
- List each conflicted file
- Help the user resolve conflicts one by one
- Use `Read` to show conflict markers and suggest resolutions

### Step 4: Post-Sync

After applying:

1. **Update version**: Update the `@buildone/swat-cli` (and typically `@buildone/swat-vscode`) version in root `package.json` to the target version
2. **Install dependencies**: Run `yarn install` to pick up any dependency changes
3. **Review changes**: Run `git diff` to show all modifications
4. **Test**: Suggest running linting and tests:
   ```bash
   yarn lint:check
   cd src/app-server-ts && yarn test
   ```
5. **Commit**: Ask the user if they want to commit the sync. Use a message like:
   ```
   chore: sync with starter template (Build.One <target-version>)
   ```

## Advanced Options

| Option | Description | Example |
|--------|-------------|---------|
| `--dry-run` | Preview without applying | `--dry-run` |
| `--from <version>` | Override start version | `--from 24.3.0-VG.119` |
| `--from <commit>` | Override start commit hash | `--from abc1234` |
| `--to <version>` | Sync to a specific version instead of latest | `--to 24.3.0-VG.130` |

Examples:
```bash
# Preview sync from current version to latest
.devcontainer/scripts/sync-from-template.sh --dry-run

# Sync to a specific version (not latest)
.devcontainer/scripts/sync-from-template.sh --to 24.3.0-VG.130

# Re-sync from a specific older version
.devcontainer/scripts/sync-from-template.sh --from 24.3.0-VG.105 --to 24.3.0-VG.130
```

## Excluded Files (Project-Specific)

These files are never overwritten by the sync:

- `package.json` / `*/package.json` — project names, versions, custom dependencies
- `yarn.lock` — regenerated from package.json
- `CLAUDE.md` / `README.md` — project documentation
- `.env` / `.env.*` — environment configuration
- `src/data/` — data definitions
- `src/app-server-ts/src/drizzle/schema/` — database schema
- `src/app-server-ts/drizzle/` — migrations
- `src/app-server-ts/src/server-actions/` — custom server actions
- `src/web-app/src/pages/` — frontend pages
- `src/web-app/src/components/` — frontend components
- `src/web-app/nuxt.config.ts` — Nuxt configuration

If the user needs to check an excluded file, compare manually:
```bash
# In the dry-run output, the template is cloned to a temp dir.
# To compare manually, clone and diff:
git clone --single-branch --branch develop https://github.com/build-one-labs/starter.git /tmp/starter-template
diff src/web-app/nuxt.config.ts /tmp/starter-template/src/web-app/nuxt.config.ts
```

## Troubleshooting

### "Could not find commit for version"
The version in `package.json` doesn't match any commit message in the template. This can happen if the version was set manually. Use `--from` with a known version or commit hash. The script will show the 10 most recent template versions to help.

### Patch fails to apply
If the patch has too many conflicts:
1. Run with `--dry-run` to review the patch first
2. Narrow the range: sync incrementally with `--to` targeting intermediate versions
3. Review conflicted files and resolve manually

### Large diff on first sync
For projects that haven't synced in many versions, the diff may be large. Recommend syncing incrementally using `--to` with intermediate versions.

## Files and Locations

| File | Purpose |
|------|---------|
| `.devcontainer/scripts/sync-from-template.sh` | Sync script |
| `.claude/skills/sync-from-template.md` | This skill file |
| `package.json` → `@buildone/swat-cli` | Source of current template version |
