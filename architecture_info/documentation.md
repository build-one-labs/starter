## Documentation

### Project Documentation Location

All project documentation is located in **`src/web-docs/docs/`**. This comprehensive documentation covers:

- Getting Started guides (Introduction, Quick Start, Codespaces setup)
- Architecture and fundamentals
- Component library reference (Form, FileUpload, etc.)
- Custom component development
- Data adapters and REST API integration
- Theming and styling with TailwindCSS
- Database and migrations with Drizzle ORM
- Schema to Blueprint conversion

**To find specific documentation topics, see:** [.claude/docs/web-docs-index.md](.claude/docs/web-docs-index.md)

This index catalogs all available documentation with file paths and topic descriptions, making it easy to locate relevant guides.

**When adding new documentation:**

- Place files in the appropriate `src/web-docs/docs/` subdirectory
- Update `src/web-docs/docs/.vitepress/config.ts` navigation
- Update `.claude/docs/web-docs-index.md` with new entry
- Follow guidelines in `.claude/docs/documentation.md`

**Access documentation:**
- Local: `b1 documentation` (opens port 5173)
- Online: https://docs.build.one

### VitePress Documentation Framework

Documentation uses **VitePress** (Vue-powered static site generator built on Vite).

**Key features:** Markdown with Vue components, custom containers (`::: tip`, `::: warning`, `::: danger`), syntax highlighting, dark mode

**Configuration:** `src/web-docs/docs/.vitepress/config.ts`

**For detailed documentation guidelines and best practices, see:** [.claude/docs/documentation.md](.claude/docs/documentation.md)