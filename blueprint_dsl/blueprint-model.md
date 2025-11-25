# Build.One Blueprint Model – Agent Reference

> **Audience:** AI coding / refactoring agents working with Build.One blueprints  
> **Goal:** Explain how the blueprint is structured so you can safely read, modify, and generate blueprint JSON.

---

## 1. Core Concepts & Glossary

**Blueprint**  
The complete **application model** stored as granular JSON objects. It describes:
- UI (screens, layouts, components)
- Data (fields, entities, queries, datasources)
- Logic (events, code hooks, actions)
- Wiring (links between all of the above)

You are **not** editing “pages” or “screens” directly. You are editing a **graph of typed objects** that together define the app.

---

### 1.1 Object-Type

An **Object-Type** is the *abstract kind* of an object. Examples:

- `Screen`
- `Layout`
- `Panel`
- `Grid`
- `GridColumn`
- `Form`
- `FormField`
- `Button`
- `Toolbar`
- `Entity`
- `DataField`
- `Query`
- `DataSource`
- `CodeAction` (or similar logic/code hook types)

The Object-Type defines:

1. **Attributes**  
   - Scalar properties like `title`, `selectionMode`, `pageSize`, `icon`, `visible`, etc.

2. **Allowed child object-types**  
   - Which other object-types may be instantiated **inside** this object  
     (e.g. `Grid` may contain instances of `GridColumn`)

3. **Events**  
   - Named hooks such as `onLoad`, `onClick`, `onBeforeSave`, `onRowSelected`, etc.

4. **Link capabilities**  
   - Which **link-types** this object-type may participate in  
   - Whether it may act as `SOURCE`, `TARGET`, or both for each link-type  
   - Example: `Query` may act as `DATA-SOURCE`; `Grid` and `Form` may act as `DATA-TARGET`

Object-Types can support **inheritance**, so shared behavior/attributes are defined in base types.

> ⚠️ As an agent: **Do not invent new Object-Types** unless the task explicitly says so. Work with the existing meta-model. If you need to know which Object-Types exist, then use the corresponding tool from the Blueprint MCP to query the blueprint database. IMPORTANT: Consider this document only as an explanation of the Blueprint concept, and the objects and object-types mentioned here as samples. The only source of truth is in the Blueprint database, which you can query using the Blueprint MCP.

---

### 1.2 Object / ObjectMaster / Instance

In this document we use:

- **Object**: a concrete blueprint element (e.g. a specific Screen, Grid, Query)
- **ObjectMaster**: a named object that implements an abstract Object-Type
- **Instance**: a reference to an ObjectMaster that is placed inside another object

Examples:

- `CustomerForm`  
  - Object-Type: `Form`  
  - Role: a form specifically for customer data  
  - This is an **ObjectMaster**.

- `CustomerSearchScreen`  
  - Object-Type: `Screen`  
  - Contains instances of `CustomerGrid`, filter form, toolbar, etc.

- Inside `CustomerSearchScreen`, you might have:
  - One instance of `CustomerGrid` (Object-Type `Grid`, Master name `CustomerGrid`)
  - One instance of `CustomerFilterForm` (Object-Type `Form`)
  - Etc.

Each instance typically has:
- A unique **instance ID** (usually a GUID)
- A reference to its ObjectMaster (by name/ID)
- Optional **overrides** of the master’s attributes (instance-level customization)

> ✅ As an agent: treat IDs as stable references. When cloning or creating objects, be careful whether you should keep, regenerate, or update IDs and references.

---

### 1.3 Template Objects (`template` flag)

Each ObjectMaster has a boolean attribute, usually called `template` (or similar):

- `template = false` → this is a **specific implementation**
  - Example: `CustomerForm`, `OfferSearchScreen`

- `template = true` → this is a **template object**, used as a reusable pattern
  - Example: `SimpleSearchScreen` (a generic “simple search” layout)

Structurally, **template objects are identical** to normal objects:

- Same attributes
- Same child instances
- Same links

The difference is **semantic**: template objects usually contain **placeholder instances**.

#### Example: Template `SimpleSearchScreen`

- Object-Type: `Screen`
- `template = true`
- Contains (for example):
  - `PlaceholderQuery` (Object-Type `Query`)
  - `PlaceholderGrid` (Object-Type `Grid`)
- Has a **DATA link** configured:
  - From `PlaceholderQuery` (DATA-SOURCE)
  - To `PlaceholderGrid` (DATA-TARGET)
- Also contains layout, panels, toolbars, etc. preconfigured.

#### Instantiating From a Template

When creating a new specific Screen from a template, e.g. `CustomerSearchScreen` from `SimpleSearchScreen`:

1. **Copy attributes** from the template to the new Screen.
2. **Copy child instances** from the template.
3. Replace **placeholder instances** with **specific objects** of the same type, e.g.:
   - `PlaceholderQuery` → `CustomerQuery`
   - `PlaceholderGrid` → `CustomerGrid`
4. **Keep all links**, but update endpoints to point to the new concrete objects:
   - DATA link from `CustomerQuery` (DATA-SOURCE) to `CustomerGrid` (DATA-TARGET).
5. **Preserve instance-level attributes** (like layout, sizes, labels, etc.) from the template unless explicitly overridden.

> ✅ As an agent:  
> - When you modify a template, remember that many concrete objects may be derived from it.  
> - When creating new functionality, prefer **using an existing template** (e.g. `SimpleSearchScreen`) if it matches the pattern.

---

## 2. Global Structural Principles

1. **Everything is JSON**  
   - Blueprint state is stored as granular JSON objects and can be exported to Git.

2. **Graph of objects**  
   - The blueprint is best thought of as a **graph**:
     - Nodes = objects/instances
     - Edges = links
   - There are also containment relationships: objects containing child instances.

3. **Object identity vs. configuration**  
   - Each object/instance has a stable identity and a set of attributes/children.
   - Links refer to objects by ID, so **changing IDs breaks links**.

4. **Object-Type driven validation**  
   - Whether a child or link is allowed is determined by the object-types.

---

## 3. Links

A **Link** connects two object instances and declares a specific relationship between them.

Generic shape (conceptual):

```jsonc
{
  "id": "link-guid",
  "linkType": "DATA" | "SELECTION" | "ACTION" | "NAVIGATION" | "...",
  "sourceInstanceId": "guid-of-source-instance",
  "targetInstanceId": "guid-of-target-instance",
  "roles": {
    "sourceRole": "DATA-SOURCE" | "SELECTION-MASTER" | "...",
    "targetRole": "DATA-TARGET" | "SELECTION-DETAIL" | "..."
  },
  "parameters": {
    // link-type-specific configuration
  }
}
```

Key points:

- The **direction** of the link matters.
- Each **linkType** defines:
  - Required roles for `source` and `target` (e.g. must be DATA-SOURCE / DATA-TARGET capable)
  - Required behaviors or methods that must be implemented by the source/target objects.

### 3.1 DATA Links (DATA-SOURCE → DATA-TARGET)

This is the main pattern for connecting UI components to data.

**Definition:**

- A **DATA link** goes **FROM** the data provider (Query/DataSource)  
  **TO** the consumer (Grid/Form).

So:

- `sourceInstance` → role: **DATA-SOURCE** (e.g. `CustomerQuery`)
- `targetInstance` → role: **DATA-TARGET** (e.g. `CustomerGrid`)

The Object-Types involved declare:

- `Query` / `DataSource`:
  - may act as `DATA-SOURCE`
- `Grid` / `Form`:
  - may act as `DATA-TARGET`

The DATA link-type typically requires the SOURCE to provide data operations such as:
- `fetchNext`
- `fetchPrev`
- `fetchFirst`
- `fetchLast`
- etc.

The TARGET (e.g. a Grid) issues these operations via the link and renders whatever data it receives.

> ✅ As an agent: when you “wire up” data:
> - Bind data-producing objects (Query/DataSource) as **DATA-SOURCE**.
> - Bind visual consumers (Grid/Form) as **DATA-TARGET**.
> - Always get the **link direction correct**: SOURCE (Query) → TARGET (Grid).

### 3.2 Other Link Types (examples)

Exact link-types may vary, but typical patterns include:

- **SELECTION**  
  - Master-detail synchronization.
  - Source: master grid (providing current selection)
  - Target: detail form or detail grid (consuming selection / filtering).

- **ACTION**  
  - Connecting UI elements (buttons, menu items) to logic actions/code.
  - Source: Button
  - Target: CodeAction / backend function specification

- **NAVIGATION**  
  - Connecting UI elements to Screens (e.g. menus, tree nodes, navigation buttons).
  - Source: navigation trigger
  - Target: Screen

> ⚠️ As an agent: follow existing patterns for link-types, roles, and directions. Don’t invent new link-type semantics unless the task explicitly asks for it.

---

## 4. Data Model Objects

Blueprints model *data* in a structured way to keep UI, data, and logic loosely coupled.

### 4.1 DataField

Represents a single atomic field, roughly comparable to a database column:

- Attributes include:
  - `name`
  - `dataType` (string, number, boolean, date, etc.)
  - `length` (where relevant)
  - `nullable`
  - `defaultValue`
  - Possibly metadata like label, formatting hints, etc.

DataFields are typically generated from:

- A **Drizzle schema**, or
- An **API schema** (OpenAPI, etc.)

### 4.2 Entity

Represents a logical data structure such as a table or resource, e.g. `Customer`, `Offer`:

- Contains references to multiple **DataFields**
- May describe keys, relationships, and constraints
- Encapsulates the **domain model** independent of UI

### 4.3 Query / DataSource

Objects that define **how** data is retrieved and possibly filtered/sorted:

- Attributes may include:
  - Source Entity/Entities
  - Filter conditions
  - Sort order
  - Paging options

These are the objects typically used as **DATA-SOURCE** in DATA links.

> ✅ As an agent: Grids and Forms should usually consume data via a Query/DataSource object connected by a DATA link, not by embedding SQL/filters directly into the UI components.

---

## 5. UI Model

The UI is defined via a combination of **Layouts**, **Screens**, and **UI Components** (like Grids, Forms, Buttons, etc.).

### 5.1 Layouts

A **Layout** defines the panel structure of a Screen.

- The layout has a **name**, often describing the number/shape of panels, e.g.:
  - `3T` → 3 panels arranged so that:
    - Panel `a` at top, full width
    - Panels `b` and `c` below, each half width (looks like a “T”)
- Panels are identified by single letters: `a`, `b`, `c`, …
- Attributes include:
  - Splitter orientation (horizontal/vertical)
  - Relative panel sizes
  - Min/max sizes
  - Collapsibility

> ✅ As an agent: when placing UI components on a Screen, you assign them to a **panel** (`a`, `b`, `c`, …) defined by the Screen’s Layout.

### 5.2 Screens

A **Screen** is the main unit of UI the user interacts with:

- Attributes:
  - `name`
  - `title`
  - Reference to a **Layout**
  - Possibly routing info (how the screen is opened)

- Contains:
  - Instances of components (Grids, Forms, Toolbars, Buttons, etc.)
  - Links between those components (DATA, SELECTION, ACTION, NAVIGATION)

The Screen doesn’t directly “know” how to access data or perform actions. Instead, it coordinates components and links.

### 5.3 Components: Grid, Form, etc.

Each component is itself an ObjectMaster/instance of its Object-Type.

#### Grid

- Object-Type: `Grid`
- Attributes (examples):
  - `selectionMode`
  - `pageSize`
  - `showRowNumbers`
  - `sortable`
  - etc.

- **Columns are NOT attributes**.  
  They are **child objects** of type `GridColumn` added as instances inside the Grid.

So conceptually:

```jsonc
{
  "id": "grid-guid",
  "type": "Grid",
  "attributes": {
    "selectionMode": "single",
    "pageSize": 50
  },
  "children": [
    {
      "id": "col1-guid",
      "type": "GridColumn",
      "attributes": {
        "field": "customerNumber",
        "header": "Customer No"
      }
    },
    {
      "id": "col2-guid",
      "type": "GridColumn",
      "attributes": {
        "field": "name",
        "header": "Name"
      }
    }
  ]
}
```

- A Grid is usually connected to a Query/DataSource via a **DATA link**:
  - Source: Query (DATA-SOURCE)
  - Target: Grid (DATA-TARGET)

#### Form

- Object-Type: `Form`
- Has child `FormField` objects representing individual inputs
- Attributes include layout hints, validation mode, etc.
- Typically linked via a DATA link to a data provider (Query/DataSource or entity-level datasource).

#### Buttons, Toolbars, etc.

- Usually participate in **ACTION** and/or **NAVIGATION** links:
  - Button → CodeAction (ACTION)
  - Button / menu item → Screen (NAVIGATION)

> ✅ As an agent: build UIs by composing Screens, Layouts, and components, and wire them together with links instead of hard-coding behavior inside the components.

---

## 6. Logic & Pro-Code Integration

Blueprint objects also represent integration points with pro-code (TypeScript, server logic, etc.).

### 6.1 Code Objects (e.g. `CodeAction`)

These objects describe **what code to call**, not the code itself.

Typical attributes:

- `fileName` (TS module/file name)
- `functionName` (exported function)
- Optional `payload` / configuration
- Optional metadata (sync/async, error handling, etc.)

### 6.2 Events → Code

Object-Types declare events like `onClick`, `onLoad`, `onBeforeSave`, etc.

Concrete objects (Buttons, Screens, Forms…) attach to these events by creating **links** to Code objects, typically via an `ACTION` link-type.

Example:

- Button `CreateCustomerButton`:
  - Event: `onClick`
  - Has an ACTION link:
    - Source: the button instance
    - Target: `CreateCustomerAction` (CodeAction object)
- At runtime, when the button is clicked, the framework resolves and invokes the configured function.

> ✅ As an agent: when you add or change behavior, prefer to:
> - Create / update Code objects, and
> - Wire them via links from UI components’ events, instead of embedding code directly in UI objects.

---

## 7. Versioning & Workflow Considerations (For Agents)

- Blueprints are exported as JSON and stored in **Git** alongside code.
- Development usually follows a feature-branch workflow:
  - Branch from `develop`
  - Modify blueprint & code
  - Commit changes
  - Create PR to merge into `develop`

### 7.1 Safe Editing Rules

As an AI agent, follow these principles:

1. **Preserve IDs and references**  
   - Do not change object or instance IDs unless you are explicitly cloning/creating new elements.
   - If you copy/duplicate objects, generate new IDs and update all relevant references/links.

2. **Respect template semantics**
   - Don’t arbitrarily flip `template` true/false.
   - When creating new screens or patterns, consider leveraging existing templates (e.g. `SimpleSearchScreen`) and performing placeholder substitution.

3. **Keep link directions correct**
   - For DATA links: SOURCE = Query/DataSource; TARGET = Grid/Form.
   - For ACTION links: SOURCE = UI trigger (Button); TARGET = Code.
   - For NAVIGATION links: SOURCE = navigation trigger; TARGET = Screen.

4. **Use child objects instead of bloated attributes**
   - Complex structures like Grid columns or Form fields are **child objects**, not just JSON arrays of scalars.

5. **Align with Object-Type constraints**
   - Only add child objects or links that the Object-Type allows.
   - If in doubt, inspect similar existing objects and mirror their structure.

---

## 8. Quick Checklist for Blueprint Changes

When you are asked to modify or generate blueprint content, use this checklist:

1. **Identify the Object-Types involved**
   - Screen, Grid, Form, Query, Entity, etc.

2. **Decide whether you’re editing:**
   - A specific implementation (`template = false`), or
   - A template (`template = true`).

3. **Create / reuse data objects**
   - DataFields → Entities → Queries/DataSources.

4. **Create / modify UI objects**
   - Screens → Layout → Panels → Components (Grid, Form, etc.).
   - Use child objects for columns/fields.

5. **Wire with links**
   - DATA links: Query/DataSource → Grid/Form.
   - SELECTION links: master grid → detail form/grid.
   - ACTION links: Button → CodeAction.
   - NAVIGATION links: navigation trigger → Screen.

6. **Check IDs & references**
   - Every new object/instance has a unique ID.
   - All links refer to existing instance IDs.

7. **Respect templates**
   - If deriving from a template, replace placeholders and keep copied attributes & links consistent.

If you follow these rules, you’ll produce blueprint changes that are structurally valid and consistent with the Build.One model.
