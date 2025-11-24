# Build.One Starter Template

A production-ready monorepo template for building modern web applications with NestJS backend and Nuxt.js frontend, powered by the Build.One framework.

## What's Included

This template provides a complete full-stack application starter with:

### Backend (NestJS)
- **NestJS** API server with TypeScript
- **Drizzle ORM** for type-safe database operations with PostgreSQL
- **Swagger/OpenAPI** documentation
- **Authentication** with Passport and Bearer token strategy
- **Server Actions** pattern for backend business logic
- **Event-driven architecture** with global event handlers
- Database schema ready to be defined

### Frontend (Nuxt.js)
- **Nuxt 3** with TypeScript
- **PrimeVue** UI component library
- **Pinia** state management
- **Build.One Web Framework** integration
- Image optimization with @nuxt/image

### DevOps & Tooling
- **GitHub Codespaces** ready with full B1 Framework integration
- **CircleCI** configuration with dynamic pipelines
- **Yarn 4** workspaces for monorepo management
- **ESLint** and **Prettier** for code quality
- **Jest** testing setup
- Dev container configuration
- **n8n Automation Hub** for workflow automation
- **Portainer** integration for container management

## Prerequisites

- **Node.js** 24.x or later
- **Yarn** 4.1.1 (included via packageManager)
- **PostgreSQL** database
- **Docker** (optional, for development container)
- **GitHub Codespaces** (recommended) - The B1 Framework is optimized for GitHub Codespaces

## GitHub Codespaces Setup

The B1 Framework is designed to work seamlessly with GitHub Codespaces. For the development environment to function correctly, configure the following secrets in your repository.

### Setting Up Secrets

1. Navigate to your repository settings
2. Go to **Secrets and variables** > **Codespaces**
3. Add each required secret with its corresponding value
4. Restart the Codespace for changes to take effect

### Required Secrets

#### Database Credentials

- **`APP_DATABASE_CREDENTIALS`** (Required)
  - Application database credentials in `username:password` format
  - Used to auto-generate `APP_DATABASE_URL`
  - Required for `app_db_server` access

- **`B1_DATABASE_CREDENTIALS`** (Required)
  - Build.One platform database credentials in `username:password` format
  - Used to auto-generate `B1_DATABASE_URL`
  - Required for `b1_db_server` access

#### Authentication & Security

- **`BETTER_AUTH_SECRET`** (Required)
  - Secret key for Better Auth authentication system
  - Used for JWT token signing and session management
  - Must be a secure random string (minimum 32 characters recommended)

#### Build.One Platform

- **`BUILDONE_TOKEN`** (Required)
  - API token for Build.One platform access
  - Used for CLI authentication with Build.One services
  - Obtain from Build.One platform account settings

- **`BUILDONE_USER`** (Required)
  - Username for Build.One platform
  - Associated with `BUILDONE_TOKEN` for platform access

#### Automation Hub (n8n)

- **`B1_AUTOMATION_HUB_EMAIL`** (Required)
  - Email address for n8n authentication
  - Used for n8n user account creation and login

- **`B1_AUTOMATION_HUB_PASSWORD`** (Required)
  - Password for n8n authentication
  - Secure password for n8n instance access

- **`B1_AUTOMATION_HUB_USER`** (Required)
  - Username for n8n authentication
  - n8n user account identifier

### Optional Secrets

#### Blueprint Integration

- **`BLUEPRINT_MCP_AUTH`** (Optional)
  - Authentication credentials for Blueprint MCP server
  - Format: `username:password`
  - Required for Blueprint DSL operations and object management

#### CI/CD Integration

- **`CIRCLECI_API_TOKEN`** (Optional)
  - CircleCI API token for pipeline operations
  - Required only if using CircleCI integration features
  - Obtain from CircleCI account settings > Personal API Tokens

#### AI & Development Tools

- **`CLAUDE_ORG_UUID`** (Optional)
  - Claude organization UUID for AI integration
  - Required for Claude Code AI features
  - Obtain from Claude account organization settings

- **`CONTEXT7_API_TOKEN`** (Optional)
  - Context7 API token for documentation integration
  - Required for Context7 MCP server functionality
  - Obtain from Context7 account settings

#### Deployment & Infrastructure

- **`PORTAINER_API_TOKEN`** (Optional)
  - Portainer API token for container management
  - Required only for deployment operations via Portainer
  - Generate from Portainer UI: User settings > Access tokens

- **`PORTAINER_URL`** (Optional)
  - Portainer instance URL
  - Format: `https://portainer.example.com`
  - Required when using Portainer deployment features

### Security Best Practices

- ⚠️ **Never commit secrets to the repository**
- 🔄 Rotate tokens and passwords regularly
- 🔐 Use strong, randomly generated values for authentication secrets
- 👥 Limit secret access to only necessary team members
- 📝 Document which secrets are in use for your project

## Getting Started

### 1. Use This Template

Click the "Use this template" button on GitHub to create a new repository from this template.

### 2. Configure GitHub Codespaces (Recommended)

Before starting development, configure the required secrets for GitHub Codespaces. See the [GitHub Codespaces Setup](#github-codespaces-setup) section above for detailed instructions.

**Quick setup:**
1. Go to your repository **Settings** > **Secrets and variables** > **Codespaces**
2. Add all required secrets listed in the setup section
3. Create a new Codespace from your repository

### 3. Clone Your Repository (Local Development)

If not using Codespaces:

```bash
git clone <your-repository-url>
cd <your-repository-name>
```

### 4. Install Dependencies

```bash
yarn install
```

### 5. Configure Environment (Local Development Only)

If not using Codespaces, create environment configuration for the backend:

```bash
cd src/app-server-ts
cp .env.example .env  # If available, or create new .env
```

Required environment variables:
- `APP_DATABASE_URL` - PostgreSQL connection string
- `SECHUB_TOKEN` - Authentication token for API requests

**Note:** In GitHub Codespaces, these are automatically configured from your repository secrets.

### 6. Setup Database

The starter includes a sample database schema with tables for clients, customers, invoices, items, offers, orders, payments, products, sales representatives, and taxes. You can modify this schema in `src/app-server-ts/src/drizzle/schema/` to fit your needs.

To apply the existing migrations:

```bash
cd src/app-server-ts

# Run existing migrations
yarn db:migrate

# Seed initial data (optional)
yarn database:seed
```

To create new migrations after modifying the schema:

```bash
# Generate new migration
yarn db:migrate:generate <migration_name>

# Run migrations
yarn db:migrate
```

### 7. Start Development Servers

**Backend:**
```bash
cd src/app-server-ts
yarn start:dev
```
The API will be available at `http://localhost:3000`

**Frontend:**
```bash
cd src/web-app
yarn dev
```

## Project Structure

```
.
├── .circleci/              # CircleCI configuration
├── src/
│   ├── app-server-ts/      # NestJS backend application
│   │   ├── src/
│   │   │   ├── api/        # REST API endpoints
│   │   │   ├── drizzle/    # Database schema and migrations
│   │   │   ├── events/     # Event handlers
│   │   │   └── server-actions/ # Business logic actions
│   │   └── test/           # Backend tests
│   ├── data/               # Data definitions
│   └── web-app/            # Nuxt.js frontend application
│       └── src/
│           └── components/ # Vue components
└── package.json            # Root workspace configuration
```

## Development Commands

### Workspace-level (run from root)

```bash
# Linting
yarn lint:check              # Check all workspaces
yarn lint:fix                # Fix all workspaces

# Dependency management
yarn audit:ws                # Security audit
yarn ncu:ws                  # Check for updates
yarn syncpack:check          # Check version consistency
yarn syncpack:fix            # Fix version mismatches
```

### Backend (run from src/app-server-ts)

```bash
# Development
yarn start:dev               # Dev server with hot reload
yarn start:debug             # Dev server with debugger
yarn build                   # Build for production

# Testing
yarn test                    # Run unit tests
yarn test:watch              # Watch mode
yarn test:cov                # With coverage
yarn test:e2e                # End-to-end tests

# Database
yarn db:migrate:generate <migration_name>  # Generate migration with name
yarn db:migrate              # Run migrations
yarn database:seed           # Seed database

# Code quality
yarn lint                    # Check linting
yarn lint:fix                # Fix linting issues
```

### Frontend (run from src/web-app)

```bash
# Development
yarn dev                     # Dev server
yarn build                   # Production build
yarn preview                 # Preview production build
yarn generate                # Generate static site

# Code quality
yarn lint                    # Check linting
yarn lint:fix                # Fix linting issues
```

## Technology Stack

### Backend
- [NestJS](https://nestjs.com/) - Progressive Node.js framework
- [Drizzle ORM](https://orm.drizzle.team/) - TypeScript ORM
- [PostgreSQL](https://www.postgresql.org/) - Database
- [Passport](http://www.passportjs.org/) - Authentication
- [Swagger](https://swagger.io/) - API documentation
- [Jest](https://jestjs.io/) - Testing framework

### Frontend
- [Nuxt 3](https://nuxt.com/) - Vue.js framework
- [Vue 3](https://vuejs.org/) - Progressive JavaScript framework
- [PrimeVue](https://primevue.org/) - UI component library
- [Pinia](https://pinia.vuejs.org/) - State management
- [TypeScript](https://www.typescriptlang.org/) - Type safety

### Build.One Framework
- `@buildone/app-server-tslib` - Backend utilities
- `@buildone/web-framework` - Frontend framework
- `@buildone/web-framework-layer` - Nuxt layer
- `@buildone/swat-cli` - Development CLI
- `@buildone/swat-circleci` - CI/CD integration

## Database Schema

The starter includes a sample database schema with the following tables:
- **clients** - Client company information
- **customers** - Customer records
- **invoices** - Invoice management
- **invoice_items** - Invoice line items
- **invoice_item_taxes** - Tax details for invoice items
- **items** - Product/service items
- **offers** - Sales offers and quotes
- **orders** - Order management
- **order_items** - Order line items
- **payments** - Payment tracking
- **product_categories** - Product categorization
- **products** - Product catalog
- **sales_reps** - Sales representative information
- **taxes** - Tax definitions

You can modify or replace these tables based on your project's needs:

1. **Modify existing tables** or **create new ones** in `src/app-server-ts/src/drizzle/schema/`
2. **Export tables** from `src/app-server-ts/src/drizzle/schema/index.ts`
3. **Generate migrations** with `yarn db:migrate:generate <migration_name>`
4. **Run migrations** with `yarn db:migrate`

Example table definition:
```typescript
// src/app-server-ts/src/drizzle/schema/users.table.ts
import { pgTable, serial, varchar, timestamp } from 'drizzle-orm/pg-core';

export const users = pgTable('users', {
  id: serial('id').primaryKey(),
  email: varchar('email', { length: 255 }).notNull().unique(),
  name: varchar('name', { length: 255 }),
  createdAt: timestamp('created_at').defaultNow().notNull(),
});
```

## Server Actions

Server actions provide a pattern for defining backend business logic:

```typescript
@B1Service({ basePath: 'samples' })
export class Weather {
  @B1Action({ description: 'Get weather info' })
  async info({ body }: B1ActionPayload<WeatherPayload>) {
    // Implementation
  }
}
```

Add new server actions in `src/app-server-ts/src/server-actions/`.

## API Documentation

When the backend is running, Swagger documentation is available at:
- `http://localhost:3000/api` - Swagger UI
- `http://localhost:3000/api-json` - OpenAPI JSON

## Authentication

The API uses Bearer token authentication. Include the token in requests:

```bash
curl -X POST http://localhost:3000/server-actions/samples-weather/info \
  -H "Authorization: Bearer ${SECHUB_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"lat":"52","lon":"7.6"}'
```

## Customizing the Template

After creating your repository from this template:

1. **Update package.json** - Change name, repository URL, and author
2. **Customize database schema** - Modify or replace the sample tables in `src/app-server-ts/src/drizzle/schema/`
3. **Add server actions** - Create new business logic in `src/app-server-ts/src/server-actions/` (see the Weather sample in `samples/`)
4. **Build frontend** - Add components in `src/web-app/src/components/`
5. **Configure CI/CD** - Update `.circleci/config.yml` for your deployment needs
6. **Update this README** - Document your specific application

## CI/CD

The template includes CircleCI configuration with:
- Automatic change detection
- Conditional builds for backend/frontend
- Multiple pipeline configurations (deploy, tag, audit)

Configure CircleCI in your repository settings and update the base branch in `.circleci/config.yml` if needed.

## Contributing

When working with this codebase:
1. Run `yarn lint:check` before committing
2. Write tests for new features
3. Update documentation as needed
4. Follow the existing code patterns

## Additional Documentation

- See [CLAUDE.md](./CLAUDE.md) for AI coding assistant guidance
- Check individual workspace README files for specific documentation

## Support

For issues related to:
- **Build.One framework** - Contact Build.One support
- **GitHub Codespaces setup** - Verify all required secrets are configured correctly
- **Your application** - Use your repository's issue tracker
- **Template issues** - Report to the template repository

### Troubleshooting Codespaces

If your Codespace isn't working correctly:
1. Verify all required secrets are set in repository settings
2. Restart the Codespace after adding/updating secrets
3. Check the Codespace logs for missing environment variables
4. Ensure database credentials are in the correct `username:password` format

## License

MIT
