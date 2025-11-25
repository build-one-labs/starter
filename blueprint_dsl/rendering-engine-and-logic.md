# Build.One Rendering Engine & Logic – Agent Reference

> **Audience:** AI coding / refactoring agents working with Build.One  
> **Goal:** Explain how the runtime rendering engine works, how it uses the blueprint, and how logic is attached.

This document complements the **Blueprint Model – Agent Reference**. It focuses on **runtime behavior**, not just structure.

---

## 1. High-Level Role of the Rendering Engine

The **rendering engine** is the browser-side runtime that:

1. Loads the **blueprint JSON** (objects, instances, links, layouts, logic references).
2. Builds an **in-memory object graph** for the requested Screen or application area.
3. **Renders the UI** using the configured components (Nuxt/Vue/PrimeVue stack).
4. Manages **data flow** via links (e.g., DATA links).
5. Executes **logic** in response to UI events via **logic objects**.

Important separation:

- **Blueprint** = declarative model (what exists, how it’s wired).
- **Rendering engine** = interpreter/runtime (how that model is instantiated and executed in the browser).
- **TypeScript code** = actual implementation of business logic, living outside the blueprint.

As an AI agent, you primarily manipulate the **blueprint model**, not the rendering engine code.

---

## 2. Links vs. Events (Very Important Distinction)

The rendering engine uses two fundamentally different mechanisms:

1. **Links**  
   - Connect objects in structural / data relationships.
   - Example: DATA links connecting Queries/DataSources to Grids/Forms.

2. **Events bound to logic objects**  
   - Drive behavior in response to user interactions.
   - Example: `Button.onClick` event pointing to a logic object.

> **There is no `ACTION` link type.**  
> Behavior is **not** modeled as a link. It is modeled as **events referencing logic objects**.

### 2.1 What Links Are Used For

Links describe structural connections, such as:

- **DATA links**
  - FROM Query/DataSource (DATA-SOURCE)
  - TO Grid/Form (DATA-TARGET)
- Potentially other non-behavioral relations (e.g. selection/master-detail, navigation, etc., if modeled as links).

Links are **not** used to connect UI events to code. That is the job of events and logic objects.

### 2.2 What Events + Logic Are Used For

Events are defined at the **object-type** level, for example on `Button`:

- `onClick`
- (Potentially others, depending on the type.)

Concrete objects then **bind those events to logic objects** using attributes like:

```jsonc
{
  "type": "Button",
  "attributes": {
    "caption": "Save",
    "onClickLogicId": "saveCustomerLogic" // example attribute
  }
}
```

At runtime, when the user clicks the button, the rendering engine:

1. Sees that `onClick` is configured.
2. Resolves the referenced **logic object**.
3. Calls the corresponding TypeScript function with an appropriate payload.

No link objects are involved in this step.

---

## 3. Data Flow at Runtime (via Links)

### 3.1 DATA Links: DATA-SOURCE → DATA-TARGET

The main standardized link type for data is a **DATA link**, which:

- Goes **FROM** a Query/DataSource (DATA-SOURCE)
- Goes **TO** the consumer component (DATA-TARGET), such as a Grid or a Form

Conceptually, a DATA link looks like:

```jsonc
{
  "id": "link-guid",
  "linkType": "DATA",
  "sourceInstanceId": "query-instance-guid",
  "targetInstanceId": "grid-instance-guid",
  "roles": {
    "sourceRole": "DATA-SOURCE",
    "targetRole": "DATA-TARGET"
  },
  "parameters": {
    // DATA link-specific config (e.g., paging strategy, etc.)
  }
}
```

Runtime behavior:

- When the GRID (DATA-TARGET) needs data, the engine:
  - Locates its incoming DATA link.
  - Uses the source instance (Query/DataSource) to fetch data.
  - Expects the source side to support operations like `fetchFirst`, `fetchNext`, `fetchPrev`, `fetchLast`, etc.

The **object-types** declare link capabilities:

- `Query` / `DataSource`:
  - Can act as **DATA-SOURCE**.
- `Grid` / `Form`:
  - Can act as **DATA-TARGET**.

> **As an agent:**  
> - Always wire data via a **DATA link from Query/DataSource to Grid/Form**.  
> - Always get the direction correct: source (Query/DataSource) → target (Grid/Form).

### 3.2 Other Link Types

There may be other structural link-types (e.g. for master-detail selection, navigation, etc.) depending on the current meta-model. Key rule:

- Links are for **structural / data relationships**, not for executing code.

If you’re unsure how to model something, look for **existing patterns** in the blueprint rather than inventing new link-types.

---

## 4. Logic Objects & TypeScript Functions

Logic objects are blueprint objects that describe **how to reach the real TypeScript code**, and **what payload/interface** is expected.

### 4.1 What a Logic Object Represents

A logic object typically contains:

- **Identity & type**:
  - `id`, `name`
  - Possibly a `logicType` (e.g. command, query, validation, etc.).

- **Code entry point information**:
  - `fileName` – module/file where the function lives (TypeScript code in the IDE).
  - `functionName` – exported function to call.

- **Payload/interface description**:
  - Either as:
    - Named interfaces, or
    - Schema-like structures inside the blueprint.
  - Describes **what data** the function expects (e.g. `customerId`, current form values, selection info, etc.).

- **Static configuration**:
  - Optional parameters, flags, or default values to be included in every call.

**Important:**  
The logic object does **not** contain TypeScript code. The actual implementation is in regular `.ts` files in the development environment.

### 4.2 Where the Code Lives

- TypeScript functions referenced by logic objects live in the normal source tree (IDE-managed files).
- They are versioned and built as part of the regular codebase, not as part of the blueprint.
- The blueprint only provides a **stable contract** pointing to those functions.

> **As an agent:**  
> - You may safely change logic object metadata (e.g. function name, file name, payload config) if the task requires it.  
> - You **must not** assume you can modify the actual TypeScript implementation via blueprint changes. That happens in the codebase, not in the blueprint.

---

## 5. Events and Logic at Runtime

### 5.1 Event Definition at Object-Type Level

Each object-type can declare **which events it supports**, for example:

- Object-Type: `Button`
  - Events: `onClick`
- Object-Type: `Screen`
  - Events: `onLoad`, `onBeforeClose`
- Object-Type: `Form`
  - Events: `onBeforeSave`, `onAfterSave`, `onValidate`, …

The blueprint for the object-type defines:

- The **names** of the events.
- How they are configured (e.g. single logic reference, multiple, etc.).

### 5.2 Binding Events to Logic in Concrete Objects

For a specific object (e.g. a particular `Button` instance), the blueprint stores:

- Attributes like `onClickLogicId` (or similar) that reference **logic object IDs**.

Example (conceptual):

```jsonc
{
  "id": "btn-save-guid",
  "type": "Button",
  "attributes": {
    "caption": "Save",
    "onClickLogicId": "logic-save-customer"
  }
}
```

And the logic object might look like:

```jsonc
{
  "id": "logic-save-customer",
  "type": "LogicAction",
  "attributes": {
    "fileName": "customer/saveCustomer.ts",
    "functionName": "saveCustomer",
    "payloadInterface": "SaveCustomerPayload"
  }
}
```

### 5.3 Runtime Execution Flow for Events

When the UI runs and the user interacts:

1. **Event triggered in UI**:  
   - e.g. user clicks the button.

2. **Rendering engine resolves the event config**:  
   - Checks which logic object(s) are attached to `onClick` for that button.

3. **Resolve code entry point**:  
   - From the logic object: `fileName` + `functionName`.

4. **Build payload**:
   - Based on:
     - The payload/interface definition.
     - Static configuration in the logic object.
     - Dynamic runtime context (form values, current selection, global context, etc.).

5. **Invoke TypeScript function**:
   - Calls the function in the actual codebase with the prepared payload.
   - Handles the return value / errors according to the runtime rules.

> **As an agent:**  
> - When tasks involve hooking up new behavior, you usually:  
>   1. Define or reuse a logic object (or adjust an existing one), and  
>   2. Set the appropriate event attributes on the UI object (e.g. `onClickLogicId`).  
> - You do **not** create “action” links for behavior.

---

## 6. Rendering & Layout

### 6.1 Screens & Layouts

At runtime, when the engine is asked to display a Screen:

1. It loads the **Screen object** by ID or name.
2. Reads its **layout** reference (e.g. layout `3T`).
3. Instantiates the layout’s **panels** (`a`, `b`, `c`, etc.) and splitters in the UI.
4. For each child component instance of the Screen:
   - Places it into the configured panel.
   - Applies instance attributes (e.g. label, visibility, sizing hints).

### 6.2 Component Instantiation

For each component instance (Grid, Form, Button, etc.):

- The engine reads its **object-type** to know:
  - Which Vue/PrimeVue component(s) to instantiate.
  - What attributes and events to support.
  - What child object-types it should render (e.g. `GridColumn` inside `Grid`).

- The engine reads its **instance attributes** to set:
  - Visual properties (caption, icon, alignment, etc.).
  - Behavioral properties (e.g. `selectionMode`, column visibility).

- For **composite components** (Grid, Form, etc.), it renders child objects:
  - Grid: renders `GridColumn` instances.
  - Form: renders `FormField` instances.

### 6.3 Data Binding

After layout and components are instantiated:

1. The engine processes **DATA links**:
   - For each Grid/Form, it looks for incoming DATA links.
   - For each such link, it binds the Grid/Form to its Query/DataSource.

2. It triggers initial data operations (e.g. `fetchFirst`) as needed.

Thus the UI is fully assembled and data-bound based on the blueprint.

---

## 7. Design- vs Runtime Responsibilities (for Agents)

### 7.1 Design-Time (Blueprint / AI / Dev)

At design-time, the blueprint (edited by humans + AI) is responsible for:

- Defining **objects** (Screens, Grids, Forms, Buttons, Queries, Entities, Logic objects, etc.).
- Choosing and configuring **layouts** and **components**.
- Defining **links**:
  - Especially DATA links Query/DataSource → Grid/Form.
- Declaring **logic objects** and mapping them to TypeScript functions.
- Binding **events** on objects to **logic objects**.

When you, as an AI agent, modify the blueprint, you operate purely in this space.

### 7.2 Runtime (Rendering Engine / Code)

At runtime, the rendering engine is responsible for:

- Interpreting the blueprint model.
- Instantiating Vue components according to object-types and attributes.
- Applying links for data flow and structural relationships.
- Attaching event handlers and dispatching to logic objects.
- Invoking the referenced TypeScript functions with appropriate payloads.

You do **not** change runtime behavior by directly editing engine code; you change it by changing the **model** (blueprint + logic metadata) and the **code implementation** (in TypeScript files).

---

## 8. Agent Checklist for Rendering/Logic-Related Changes

When you are asked to modify behavior or UI wiring, follow this checklist:

1. **Identify the Screen and components**  
   - Which Screen? Which Grid/Form/Button, etc.?

2. **Check for existing DATA links**  
   - Is the Grid/Form already connected to a Query/DataSource?  
   - If not, create a DATA link: Query/DataSource (DATA-SOURCE) → Grid/Form (DATA-TARGET).

3. **Define or reuse logic objects**  
   - If new behavior is needed, create a new logic object with:
     - Correct `fileName` and `functionName`.
     - Appropriate payload/interface description.
   - Or reuse existing logic objects if they already do what is required.

4. **Bind events to logic**  
   - For buttons: set the appropriate event attributes (e.g. `onClickLogicId`).  
   - For forms/screens: bind `onLoad`, `onBeforeSave`, etc., as needed.

5. **Preserve IDs & references**  
   - Do not change object IDs unintentionally.  
   - Ensure all references (`...LogicId`, link endpoints, etc.) point to valid objects.

6. **Respect object-type semantics**  
   - Only configure events and attributes that are actually defined for that object-type.  
   - Only add link roles allowed by the object-type definitions.

7. **Keep responsibilities separate**  
   - Use links for **data / structural relationships**.  
   - Use events + logic objects for **behavior / code execution**.

If you follow this model, you will produce blueprint changes that the rendering engine can interpret correctly, and you will stay aligned with how Build.One is designed to work.
