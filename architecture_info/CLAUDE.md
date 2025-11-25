# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Stack

### Overview

This project uses a Docker-based development stack managed by the `build-one` CLI tool. All services run as Docker containers orchestrated via Docker Compose, providing a consistent development environment.

### Core Services

The development stack consists of the following services:

#### Database Services

- **b1_db_server** (Port 5432) - Primary PostgreSQL 17 database for the build.one platform data
- **app_db_server** (Port 15432) - Application-specific PostgreSQL 17 database
- **n8n_db_server** - PostgreSQL 16 database for n8n automation workflows

#### Application Services

- **swat_app_server_ts** (Port 3000, Debug 3010) - NestJS backend API server for SWAT/Legacy application
  - Handles authentication, repository services, and legacy integration
  - Mounts workspace at `/workspace` for live development
  - Includes database seeding and credential initialization

- **app_server_ts** (Port 3001, Debug 3011) - NestJS backend API server for new applications
  - Separate database and application scope
  - Mounts workspace at `/workspace` for live development

- **web-app** - Nuxt.js frontend application
  - Current frontend architecture serving the new Vue.js 3 + Nuxt.js stack
  - Runs in development mode with hot module replacement

- **n8n** (Port 5678) - Automation Hub (n8n workflow automation)
  - Workflow automation and integration platform
  - Connected to SWAT authentication system
  - Mounts workspace for custom nodes and workflows

#### Supporting Services

- **caddy** (Ports 8080, 8081) - Reverse proxy and web server
  - Port 8080: Main application preview
  - Port 8081: Designer interface
  - Configured via `src/webui/CaddyFile`

- **pg-admin** (Port 2021) - PostgreSQL database administration interface
  - Web-based database management
  - Pre-configured connections to all database servers

- **web-docs** (Port 5173) - VitePress documentation server
  - Serves project documentation
  - Live reload during documentation development

### Network Architecture

All services run on a shared Docker network (`app-network`) enabling inter-service communication:
- Backend services communicate via service names (e.g., `http://swat_app_server_ts:3000`)
- External access via published ports (e.g., `localhost:8080`, `localhost:3000`)

### Data Persistence

- **Docker Volumes**: `b1_db_storage`, `app_db_storage`, `ah_db_storage` for database persistence
- **Workspace Mounts**: Source code and data directories mounted for live development
  - `${WORKSPACE_ROOT}/src` - Application source code
  - `${WORKSPACE_ROOT}/data` - Runtime data and uploads
  - `${WORKSPACE_ROOT}/logs` - Application logs

## Build-One CLI

The `build-one` (alias `b1`) CLI is the primary tool for managing the development stack. It's located at `src/cli/bin/build-one` and provides comprehensive project management capabilities.

### Essential Commands

**Stack Management:**
- `b1 up` - Start development stack
- `b1 down` - Stop development stack
- `b1 restart` - Restart stack
- `b1 destroy` - Destroy stack (removes volumes - USE WITH CAUTION)

**Development Tools:**
- `b1 preview [application-name] [--page path] [--verbose]` - Open application (port 8080)
  - `application-name` - Optional application name (defaults to `B1_DEFAULT_APP` env var, or `sample-app` if not set)
  - `--page path` - Optional path to open within the application (e.g., `--page users/123`)
  - `--verbose` - Optional flag to show log messages
- `b1 designer` - Open designer (port 8081)
- `b1 documentation` - Open docs (port 5173)
- `b1 dbadmin` - Open pgAdmin (port 2021)

**Data Operations:**
- `b1 import-vanguard [CLEAR]` - Import Vanguard application data
- `b1 import-automation [file]` - Import automation workflows

**Build & Deployment:**
- `b1 genver` - Generate version file
- `b1 gencom` - Generate Docker Compose deployment files
- Deploy to Portainer via CircleCI deploy pipeline (see `.circleci/pipelines/deploy/`)

**Code Generation:**
- `b1 generate <type>` - Generate configs, themes, etc.
- `b1 gen -s <service>` - Generate NestJS server actions

**For complete command list, run:** `b1 help`

### Environment Variables

Key environment variables automatically set by the CLI:
- `WORKSPACE_ROOT` - Project root directory
- `BUILDONE_CLI` - CLI installation directory
- `BUILDONE_VERSION` - Current framework version
- `APP_URL` - Application URL
- `N8N_URL` - Automation Hub URL (derived from APP_URL)
- `NODE_ENV` - Node.js environment

**Deployment credentials** (configured in CircleCI context `build-defaults`):
- `DEFAULT_PORTAINER_URL` - Portainer server URL (e.g., `https://portainer.buildone.cloud`)
- `DEFAULT_PORTAINER_API_KEY` - Portainer API access token

**Database Connection URLs:**

The CLI automatically generates database connection URLs from credentials when available:

- `APP_DATABASE_URL` - Application database connection string
  - Auto-generated from `APP_DATABASE_CREDENTIALS` if set
  - Format: `postgres://${APP_DATABASE_CREDENTIALS}@app_db_server:5432/app_db?sslmode=disable`

- `B1_DATABASE_URL` - Build.One platform database connection string
  - Auto-generated from `B1_DATABASE_CREDENTIALS` if set
  - Format: `postgres://${B1_DATABASE_CREDENTIALS}@b1_db_server:5432/b1_db?sslmode=disable`

**Note:** Both deployment configs and the CLI now automatically construct database URLs from credentials, eliminating the need to set URLs manually. Simply provide the credentials (username:password), and the URLs will be generated automatically.

### Required Secrets

For the development environment (especially GitHub Codespaces) to work correctly, the following secrets must be configured. These secrets are set as environment variables and are required by various services in the development stack.

#### Database Credentials

- `APP_DATABASE_CREDENTIALS` - **Required** - Application database credentials in `username:password` format
  - Used to auto-generate `APP_DATABASE_URL`
  - Required for app_db_server access

- `B1_DATABASE_CREDENTIALS` - **Required** - Build.One platform database credentials in `username:password` format
  - Used to auto-generate `B1_DATABASE_URL`
  - Required for b1_db_server access

#### Automation Hub (n8n)

- `B1_AUTOMATION_HUB_EMAIL` - **Required** - Email address for n8n authentication
  - Used for n8n user account creation and login

- `B1_AUTOMATION_HUB_PASSWORD` - **Required** - Password for n8n authentication
  - Secure password for n8n instance access

- `B1_AUTOMATION_HUB_USER` - **Required** - Username for n8n authentication
  - n8n user account identifier

#### Authentication & Security

- `BETTER_AUTH_SECRET` - **Required** - Secret key for Better Auth authentication system
  - Used for JWT token signing and session management
  - Must be a secure random string (minimum 32 characters recommended)

#### Build.One Platform

- `BUILDONE_TOKEN` - **Required** - API token for Build.One platform access
  - Used for CLI authentication with Build.One services
  - Obtain from Build.One platform account settings

- `BUILDONE_USER` - **Required** - Username for Build.One platform
  - Associated with BUILDONE_TOKEN for platform access

#### Blueprint Integration

- `BLUEPRINT_MCP_AUTH` - **Optional** - Authentication credentials for Blueprint MCP server
  - Format: `username:password`
  - Required for Blueprint DSL operations and object management

#### CI/CD Integration

- `CIRCLECI_API_TOKEN` - **Optional** - CircleCI API token for pipeline operations
  - Required only if using CircleCI integration features
  - Obtain from CircleCI account settings > Personal API Tokens

#### AI & Development Tools

- `CLAUDE_ORG_UUID` - **Optional** - Claude organization UUID for AI integration
  - Required for Claude Code AI features
  - Obtain from Claude account organization settings

- `CONTEXT7_API_TOKEN` - **Optional** - Context7 API token for documentation integration
  - Required for Context7 MCP server functionality
  - Obtain from Context7 account settings

#### Deployment & Infrastructure

- `PORTAINER_API_TOKEN` - **Optional** - Portainer API token for container management
  - Required only for deployment operations via Portainer
  - Generate from Portainer UI: User settings > Access tokens

- `PORTAINER_URL` - **Optional** - Portainer instance URL
  - Format: `https://portainer.example.com`
  - Required when using Portainer deployment features

**Setting Secrets in GitHub Codespaces:**

1. Navigate to your repository settings
2. Go to Secrets and variables > Codespaces
3. Add each required secret with its corresponding value
4. Restart the Codespace for changes to take effect

**Security Best Practices:**

- Never commit secrets to the repository
- Rotate tokens and passwords regularly
- Use strong, randomly generated values for authentication secrets
- Limit secret access to only necessary team members

### Deployment Configuration

The project uses a multi-layer deployment configuration system. See [.claude/docs/deployment.md](.claude/docs/deployment.md) for detailed documentation.

**Quick overview:**
- Base configs in `${BUILDONE_CLI_WORKSPACE}/deploy/`
- Custom configs in `.build/deploy/`
- Generated files in `.deploy/`
- Run `b1 gencom` to generate deployment files

### Common Workflows

**Starting Development:**
```bash
b1 up                                    # Start stack
b1 preview                               # Open preview (default app, silent)
b1 preview my-app                        # Open specific app
b1 preview my-app --page dashboard       # Open specific app at specific page
b1 preview --verbose                     # Open preview with log messages
b1 designer                              # Open designer
```

**Updating Framework:**
```bash
b1 update [version]
```

**Deployment Preparation:**
```bash
b1 genver                  # Generate version
b1 tag auto "production"   # Tag release
b1 gencom                  # Generate compose files
```

## Development Commands

All workspace commands follow the pattern: `yarn workspace <package-name> <script>`

**Common scripts:**
- `build` - Production build
- `dev` - Development server
- `lint` - Run ESLint
- `test` - Run tests

**Root level commands:**
- `yarn lint:check` / `yarn lint:fix` - ESLint all workspaces
- `yarn audit:ws` - Security audit
- `yarn syncpack:check` / `yarn syncpack:fix` - Sync versions

**For complete command reference, see:** [.claude/docs/commands.md](.claude/docs/commands.md)

## Architecture Overview

### Monorepo Structure

This is a Yarn workspace monorepo with multiple applications and services:

#### Current Frontend Architecture

- **Web Core** (`src/web-core/`) - **Component library** - Reusable Vue.js 3 components, composables, utils, services, stores, types, and packages with documentation
- **Web Framework** (`src/web-framework/`) - **Nuxt module and layer** - Automates imports of web-core functionality into Nuxt applications
- **Web App** (`src/web-app/`) - **Consumer application** - Nuxt.js application that consumes web-core via web-framework

#### Legacy Frontend

- **WebUI** (`src/webui/`) - **Legacy frontend** - Vue.js 3 with DHTMLX components and custom SWAT framework

#### Backend Services

- **App Server TS** (`src/app-server-ts/`) - NestJS backend API with Drizzle ORM
- **SWAT App Server TS** (`src/swat-app-server-ts/`) - Another NestJS application instance

#### Shared Libraries

- **App Server TypeScript Library** (`src/packages/app-server-tslib/`) - Shared NestJS library for app servers
  - Authentication and passport integration
  - Common utilities and services
  - Published to Cloudsmith registry
  - Used by both app-server-ts and swat-app-server-ts

#### Supporting Services

- **Data** (`src/data/`) - Configuration and sample data definitions
- **CLI** (`src/cli/`) - Command-line tools and deployment scripts
- **VS Code Extension** (`src/vscode-extension/`) - Build.One VS Code extension
  - Provides commands for stack management (`b1 up`, `b1 down`, etc.)
  - Quick access to preview, designer, and documentation
  - Keyboard shortcuts for common operations
  - Socket.io integration for real-time updates
- **CI/CD** (`.circleci/`) - CircleCI configuration and workflows

### Key Technologies

- **Current Frontend Stack**:
  - **Web Core**: Vue.js 3, PrimeVue, TypeScript, TailwindCSS, Pinia, Vue-i18n, FontAwesome Pro
  - **Web Framework**: Nuxt.js 3 module and layer for automated imports
  - **Web App**: Nuxt.js 3 consumer application
- **Legacy Frontend**: DHTMLX, Kendo UI, custom SWAT framework
- **Backend**: NestJS, TypeScript
- **Database**: PostgreSQL with Drizzle ORM
- **Testing**: Jest
- **Build Tools**: Vite (current), Webpack (legacy), ESBuild
- **VS Code Integration**: Custom extension for build.one commands

### Development Patterns

#### Current Frontend Architecture

The current frontend follows a modular three-layer architecture:

**Web Core (`src/web-core/`)**:

- **Component library** with reusable Vue.js 3 components using Composition API
- **PrimeVue** components for UI elements with TailwindCSS styling
- **Composables** for shared reactive logic
- **Services** for API communication and business logic
- **Stores** using Pinia for state management
- **Types** and **Utils** for shared functionality
- **Documentation** folder with usage examples and guides
- Built with **Vite** for fast bundling

**Web Framework (`src/web-framework/`)**:

- **Nuxt.js 3 module** that automatically imports web-core functionality
- **Nuxt layer** providing shared configuration and setup
- Eliminates need for manual imports in consuming applications
- Handles integration with Nuxt ecosystem (i18n, routing, etc.)

**Web App (`src/web-app/`)**:

- **Consumer application** built with Nuxt.js 3
- Automatically receives all web-core functionality via web-framework
- Focus on application-specific logic and pages
- **TypeScript** for type safety throughout the stack

#### Legacy Frontend (WebUI)

The legacy WebUI uses a custom SWAT framework built on Vue.js with:

- Component-based architecture with dynamic loading
- DHTMLX widgets integration for grids, forms, and layouts
- Kendo UI components for charts and advanced controls
- Bootstrap-based theming with custom SCSS variables
- Socket.io for real-time communication

#### Backend Architecture

- **NestJS Apps**: Use modular architecture with controllers, services, and modules
- **Shared Libraries**: Common functionality via `app-server-tslib` package
- **Database**: Drizzle ORM for TypeScript apps with PostgreSQL
- **Authentication**: JWT tokens, SAML, Active Directory, and custom strategies via Better Auth

#### Configuration Management

- Environment-specific configs in each workspace
- Shared configuration patterns across services
- Docker Compose configuration via deployment config system



## Important Notes

### Package Management

- Uses Yarn 4 with workspaces
- Dependencies should be synchronized across workspaces using syncpack
- Each workspace has its own package.json with specific scripts

### Testing Strategy

- Playwright for E2E testing with multi-browser support
- Jest for unit testing in individual workspaces
- Visual regression testing with screenshot comparisons
- Separate test environments for smoke, sanity, and regression tests

### Build Process

- Each workspace builds independently
- **Current Frontend Stack**:
  - **Web Core**: Vite-based build producing ES modules with TypeScript declarations
  - **Web Framework**: Nuxt module builder for creating distributable modules and layers
  - **Web App**: Standard Nuxt.js build process (Vite under the hood)
- **Legacy**: WebUI uses Webpack with custom configuration
- TypeScript projects use standard tsc compilation
- Docker containers available for deployment

### VS Code Extension Integration

- **Extension Package**: Build.One VS Code extension in `src/vscode-extension/`
- **Commands**: Direct access to CLI commands via VS Code command palette
- **Keyboard Shortcuts**: Alt+B (Cmd+B on Mac) prefix for quick actions
- **Real-time Updates**: Socket.io integration for live status updates
- **Deployment**: Use `yarn workspace buildone-vscode deploy:full` to install locally

## Development Focus

**Primary development should focus on the current frontend stack:**

- **Web Core (`src/web-core/`)** for reusable components, composables, services, and utilities
- **Web Framework (`src/web-framework/`)** for Nuxt.js integration and automated imports
- **Web App (`src/web-app/`)** for application-specific features and pages

This three-layer architecture enables:

- **Reusability**: Components and logic shared across applications via web-core
- **Automation**: Seamless integration via web-framework's auto-import capabilities
- **Scalability**: Easy creation of new consumer applications using the same foundation
- **Documentation**: Built-in usage examples and guides in web-core/documentation/

The WebUI and OpenEdge backend are maintained for compatibility but are not the current development direction.





## Language and Syntax Guidelines

### TypeScript and JavaScript

- Follow ESLint rules configured in workspace
- Use TypeScript for all new code in backend and frontend
- Maintain strict type safety across the stack

### Vue.js Components

- Use Composition API for all new Vue.js 3 components
- Follow PrimeVue component patterns for consistency
- Utilize TailwindCSS for styling

## CircleCI Pipelines

The Vanguard project uses CircleCI for continuous integration and deployment with a streamlined two-tier architecture that separates pipeline setup from execution.

**Pipeline URL:** https://app.circleci.com/pipelines/github/build-one-labs/vanguard

**Architecture Overview:**

The CircleCI configuration uses a consolidated two-tier structure:

1. **Setup Pipeline** (`.circleci/config.yml`)
   - Entry point with `setup: true` flag for dynamic continuation
   - Uses `continuation` orb to pass control to appropriate workflow
   - Runs Python-based change detection script (`.circleci/scripts/detect_git_changes.py`)
   - Calculates base revision from `origin/develop` for change detection
   - Maps file path changes to build parameters using regex patterns
   - Passes detected parameters to `.circleci/pipelines/build/config.yml`

2. **Build Pipeline** (`.circleci/pipelines/build/config.yml`)
   - **Consolidated configuration** containing all build workflows, jobs, commands, and executors
   - Conditional workflows triggered based on detected changes or pipeline parameters
   - Separate workflows for each workspace (webui, app servers, web-app, docs, etc.)
   - Publish workflow for releasing Docker images and NPM packages to Cloudsmith

**Change Detection Mapping:**
- `src/app-server-ts/.*` → triggers `build-app-server-ts`
- `src/packages/app-server-tslib/.*` → triggers `build-app-server-tslib` (also triggers both app servers)
- `src/cli/.*` → triggers `build-cli`
- `src/swat-app-server-ts/.*` → triggers `build-swat-app-server-ts`
- `src/vscode-extension/.*` → triggers `build-vscode-extension`
- `src/webui/.*` → triggers `build-webui`
- `src/web-{core,framework,app}/.*` → triggers `build-web-app`
- `src/web-docs/.*` → triggers `build-web-docs`
- `yarn.lock` → triggers `build-cache`

**Workflow Execution:**

Each workspace workflow runs when:
- Changes detected in relevant paths, OR
- `build-all` parameter is true, OR
- Branch is `develop` (always builds for integration testing)

**Pipeline Types:**
- `build` (default) - Intelligent build and test with Python-based change detection
- `audit` - Security audit of npm packages (`.circleci/pipelines/audit/`)
- `tag` - Version tagging and release (`.circleci/pipelines/tag/`)
- `deploy` - Deployment to environments via Portainer (`.circleci/pipelines/deploy/`)

**Supporting Resources:**
- `.circleci/defaults/build/docker/` - Dockerfiles for container images
- `.circleci/pipelines/build/*.sh` - Build and publish helper scripts
- `.circleci/scripts/` - Python change detection and utility scripts

**Key Features:**
- Consolidated build configuration (single source of truth)
- Python-based intelligent change detection with regex pattern mapping
- Dependency-aware builds (e.g., tslib changes trigger app server builds)
- Conditional workflow execution based on detected changes
- Docker image publishing to Cloudsmith registry
- NPM package publishing to Cloudsmith registry
- Slack notifications on build failures for protected branches
- CircleCI caching for Yarn dependencies
- Protected branches: `main`, `develop`, `release/*`, `hotfix/*`

**For complete CircleCI documentation, see:** [.claude/docs/circleci.md](.claude/docs/circleci.md)

## Dev-ops and Deployment

IMPORTANT: the blueprint_dsl/blueprint_deployment.md contains crucial information about how deployment of blueprint applications is done. Make sure to always check the content of that file, and adhere to what it describes for deployment tasks.

