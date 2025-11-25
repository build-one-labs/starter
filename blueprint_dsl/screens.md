# Build.One Screens Agent Spec (`agent.md`)
Version: 1.0  
Date: 2025-11-15  
Owner: Build.One (Screens)  
Audience: AI coding agents (e.g., Claude Code, Windsurf, VS Code agents) operating on Build.One blueprints

> **Purpose.** This document tells an AI agent exactly how to **create, modify, and validate UI screens** in Build.One using the blueprint model. It assumes entities and queries already exist (see separate data-access agent spec). The output of the agent is **blueprint JSON** changes committed to Git alongside code, following the Build‑Flow feature-branch model.

---

## 0) TL;DR Checklist for Any Screen Task
- [ ] Choose the right **Layout** see blueprint_dsl/layouts_in_screen.md for detailed info about layouts.  
- [ ] Create or reuse **ObjectMasters**: `Screen`, `Grid`, `Form`, `Toolbar`, `Button`, `Field`…  
- [ ] Place child objects into **named panels** of the Layout (letters `a`, `b`, `c`, …) using the **layoutPosition** attribute of the instances.  
- [ ] Wire **Links** between objects (e.g., Grid → Form selection).  
- [ ] Register **Events** (`onInit`, `onRowSelect`, `onAction`, `onSubmit`, `onError`).  
- [ ] Bind to **Entities/Queries** through DataSource attributes.  
- [ ] Validate **naming, required attributes, links, panels**, and **no orphaned objects**.  

---

## 1) Concepts & Terminology
**Blueprint** — Build.One model stored as granular JSON objects (versioned in Git).  
**ObjectType** — Template defining attributes & events (e.g., `Screen`, `Grid`, `Form`, `Toolbar`, `Button`, `Field`). Supports **inheritance** and **events**.  
**ObjectMaster** — An instance of an `ObjectType` (e.g., `CustomerSearchScreen` of type `Screen`). ObjectMasters can contain other ObjectMasters.  
**Layout** — A `Screen` attribute (**LayoutOptions**) that specifies a layout, which defines numbe and layout of panels in the screen. read blueprint/layouts_in_screens.md for detailed instructions.
**Panel** — A container inside a `Layout`. Child UI components are placed into specific panel letters.  
**Link** — Relationship between object instances (e.g., `Grid` → `Form`), with a **link-type** that defines required implementations (e.g., selection propagation, fetch).  
**Event** — Hook points implemented via blueprint logic or pro-code references (e.g., `onInit`, `onRowSelect`, `onAction`).

---

## 2) Naming Conventions
- **Screen**: `{Entity}{Purpose}Screen` (e.g., `CustomerSearchScreen`, `CustomerMaintenanceScreen`, `OfferCreateScreen`).  
- **Grid**: `{Entity}Grid` (e.g., `CustomerGrid`).  
- **Form**: `{Entity}Form` (e.g., `CustomerForm`).  
- **Toolbar**: `{Entity}{Purpose}Toolbar` (e.g., `CustomerSearchToolbar`).  
- **Buttons**: `{Verb}{Entity}Btn` (e.g., `CreateCustomerBtn`, `SaveOfferBtn`).  
- **Fields**: `{Entity}{FieldName}` (e.g., `CustomerLastName`, `LeadStatus`).  
- Use **PascalCase** names; avoid spaces; keep them stable across commits.  
- Every ObjectMaster has a stable internal GUID; names are for human readability & references in links/events.

---

## 5) Links (Selection & Data Flow)
Common link-types you will use:

**use the blueprint mcp to query the blueprint database for available link-types and how to use them for each object_type.**


## 6) Events (Screen / Grid / Form / Toolbar)
**Screen**: `onInit`, `onBeforeClose`, `onError`.  
**Grid**: `onInit`, `onRowSelect`, `onFilterChange`, `onPageChange`, `onError`.  
**Form**: `onInit`, `onChange`, `onValidate`, `onSubmit`, `onError`.  
**Toolbar**: `onAction(actionId)`, `onInit`, `onError`.

Event handlers can be blueprint logic or pro‑code callbacks described in corresponding blueprint objects (e.g., `{ fileName, functionName, payload }`).

---

**use the blueprint mcp to query the blueprint database about available attributes and which object-type supports which attribute**


## 9) Agent Behaviors & Rules
1. **Idempotence:** Re-run safe. If a Screen exists, **update in-place**; otherwise create.  
2. **References:** Validate all `entityName`, `queryName`, `sourceObjectName`, `targetObjectName`.  
3. **Layouts:** Do **not** place children into non-existent panels.  
5. **Events:** Ensure minimal handlers exist; prefer blueprint actions over pro-code unless explicitly requested.  
6. **Naming:** Enforce conventions above; never rename existing objects silently.  
7. **Compatibility:** Avoid using components not supported by the runtime target (PrimeVue-default controls are safe).  
8. **Accessibility:** Provide titles for screens. Provide labels for inputs; respect required/validation rules.  
9. **Performance:** Default grid page size ≤ 50; avoid fetching on every keystroke; debounce filters.  
10. **Security:** Do not embed secrets in metadata. Respect role-based visibility if present.

---

## 10) Validation Checklist (auto-run)
- Entities/Queries exist and are reachable.  
- Layout defined, panels referenced correctly.  
- All children named and unique within the screen.  
- Links compile, no dangling references.  
- Events compile, action targets exist.  
- Grid columns reference existing fields.  
- Form fields map to entity fields and required validations exist.  
- No orphaned ObjectMasters (i.e., declared but not placed in any panel).

---

## 12) Quick Test Steps (per screen)
1. Launch the runtime preview for the given Screen.  
2. Verify panel composition and splitter behavior.  
5. Toolbar actions invoke expected behavior (`Create`, `Edit`, `Delete`, `Save`, `Refresh`, `Open`).  
6. Validation errors block submit; success persists.

---

## 13) Examples of Natural-Language Tasks
- “Create a **maintenance screen** for `Customer` using layout `3T` with grid+form and a toolbar.”  
- “Add an **Export** action to `LeadSearchScreen` and wire it to the grid.”  
- “Change `OfferCreateScreen` to include `validUntil` date field and make it required.”  
- “Add a `status` select filter (options: New, Working, Won, Lost) to `LeadSearchScreen`.”  


## 15) Appendix: Minimal JSON Snippets

**use the blueprint mcp to query the blueprint database for samples by querying objects from the sample-app, or objects with flag template:true


## 16) Glossary
- **CRUD triad**: Search, Create, Maintenance (grid+form).  
- **Luv/Lee** (unrelated to screens but to sailing): ignore in this context.  
- **ObjectMaster**: Instance of a type; children allowed; referenced by `name`.  
- **Link-Type**: Contract describing required behaviors/methods for a link.  
- **Event**: Hook executed at runtime; can call built-ins or pro‑code.

---

## 17) Agent Self‑Verification (mandatory before finalizing)
- [ ] JSON is syntactically valid.  
- [ ] All referenced names exist (entities, queries, objects).  
- [ ] Layout and panel letters align.  
- [ ] No hidden renames; backward compatible unless task specifies otherwise.
