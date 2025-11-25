## Git Workflow - SwatFlow

The Vanguard project follows **SwatFlow**, a custom Git workflow extending OneFlow that enables parallel work on active development and hotfixes without mutual interference.

**Core Branches:**
- `develop` - Central hub for feature branches and release creation
- `main` - Optional, points to latest stable release

**Branch Types:**
- `feature/TICKET-description` - Individual features (rebase + squash merge)
- Long-Running Feature (LRF) - Complex features with subbranches (merge, no rebase)
- `release/x.y.z` - QA testing snapshots (one at a time)
- `hotfix/x.y.z-description` - Urgent production fixes from tags
- `x.y` - Maintenance markers for version families
- `lts/` - Long-term support versions

**Key Principles:**
- Feature branches: rebase onto develop before PR, squash commits on merge
- LRF branches: use merge operations only (never rebase)
- Only one release branch per source at any time
- Hotfixes contain only critical fixes, no new features
- Tags use semantic versioning (x.y.z format)
- GitVersion support for automated versioning

**Protected Branches:** `main`, `develop`, `release/*`, `hotfix/*`

**For complete SwatFlow documentation, see:** [.claude/docs/swatflow.md](.claude/docs/swatflow.md)

**Official Guide:** https://helpcenter.build.one/use-cases/swat-flow