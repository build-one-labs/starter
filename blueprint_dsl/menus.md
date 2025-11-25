
# Build.One Menus – Agent Knowledge

This document explains how **menus** work in Build.One so that an AI agent can correctly read, generate, and modify menu-related blueprint objects.

---

## 1. Core Concepts

Menus in Build.One are fully **blueprint-driven** and modeled via object-types.  
The key object-types involved are:

- **`Menu`** – a container that defines the structure of a menu (hierarchy of groups and actions).
- **`Action`** – an actionable item a user can trigger in the UI (e.g. open screen, run logic).
- **`Group`** – a logical grouping / folder inside a menu that can contain actions and/or nested groups.
- **Visual hosts** (other object-types that *display* a menu):
  - `Toolbar`
  - `Ribbon`
  - `Menu` (as a visual control, e.g. top menu bar)
  - `Sidebar`
  - (Potentially others in the future)

The **menu definition** (structure and behavior) is separate from **where it is displayed**.  
A visual host references a `Menu` and renders its content at runtime.

---

## 2. Object-Type Details

### 2.1 `Action`

An **Action** represents something the user can trigger in the UI.

Typical attributes (conceptual):

- **Display / UX**
  - `label` – text shown to the user
  - `icon` – icon identifier
  - (Possible) `tooltip`, `orderIndex`, `hotkey`
- **Behavior**
  - `logic` – what is executed when triggered
    - This might be an internal link to:
      - launch a screen
      - call backend logic
      - call client-side logic
      - or other domain-specific behaviors
  - Optionally an explicit `actionType` enum (e.g. `OpenScreen`, `RunServerAction`, `RunClientAction`, `NavigateUrl`, …)
- **Visibility / state** (possible / typical)
  - `enabledCondition`
  - `visibleCondition`
  - `role / permission` requirements

> **Key point:**  
> An Action is *always* defined as “logic plus presentation”.  
> When the user selects an Action, the associated logic is executed.

Actions are standalone blueprint objects and can be **reused** in different menus.

---

### 2.2 `Menu`

A **Menu** is a container that defines the hierarchical structure of Actions and Groups.

- Contains:
  - `Action` instances
  - `Group` instances (which can themselves contain Actions and nested Groups)
- Defines the **logical navigation model**, not the visual style.
  - Visual style/layout comes from the host object (e.g. toolbar, sidebar, ribbon).

Conceptually, a Menu is a tree:

- Root: the `Menu` object itself
- Children: `Group` and `Action` nodes

---

### 2.3 `Group`

A **Group** organizes actions inside a menu.

- Lives **inside a `Menu`** (or inside another `Group` for nesting).
- Can contain:
  - `Action` instances
  - nested `Group` instances
- Typical attributes:
  - `label`
  - `icon` (optional)
  - `orderIndex`
  - Possibly conditions (visibility, roles, feature flags, etc.)

Examples of groups:

- `Base Data`
- `Customer Data`
- `Administration`

---

### 2.4 Visual Host Object-Types

The menu itself is *not* automatically visible.  
A **visual host** object-type is responsible for rendering a menu in the UI.

Common host object-types:

- **`Toolbar`**
- **`Ribbon`**
- **`Menu`** (visual menu bar)
- **`Sidebar`**

Each such host has an attribute like:

- `menu` (or similar reference) → pointing to a `Menu` object.

At runtime, the renderer:

1. Resolves the referenced `Menu`.
2. Renders its `Group` and `Action` hierarchy according to the host type’s visual rules.

> Example:
> - A `Toolbar` might render top-level groups as button groups.
> - A `Sidebar` might render groups as collapsible sections.
> - A `Menu` bar might render top-level groups as dropdowns.

---

## 3. Relationships & Hierarchy

Conceptually, the relationships are:

- **Menu → Group / Action**
  - A `Menu` contains one or more `Group` and/or `Action` instances.
- **Group → Group / Action**
  - A `Group` can contain:
    - child `Group` instances (nested groups)
    - child `Action` instances
- **Host → Menu**
  - A `Toolbar`, `Ribbon`, `Menu` (visual), or `Sidebar` references a single `Menu`.

This allows:

- Arbitrary deep menu hierarchies with nested groups.
- Reuse of Actions across menus and groups.
- Multiple visual hosts using the same `Menu` definition (e.g. toolbar + sidebar showing different projections of the same logical navigation model, if supported).

---

## 4. Example: Simple Menu

### 4.1 Conceptual Example

Imagine a `Customer Management` module:

- `Menu`: `MainApplicationMenu`
  - `Group`: `Base Data`
    - `Action`: `OpenCustomerSearch`
    - `Action`: `OpenProductSearch`
  - `Group`: `Customer Data`
    - `Action`: `OpenCustomerDetails`
    - `Action`: `OpenCustomerOrders`

Each `Action` has logic such as:

- `OpenCustomerSearch` → launches the “CustomerSearchScreen”
- `OpenProductSearch` → launches “ProductSearchScreen”
- etc.

A `Toolbar` object on the main screen might have:

- attribute `menu = MainApplicationMenu`

At runtime, the toolbar displays:

- “Base Data” group with actions “Customers”, “Products”
- “Customer Data” group with its actions

---

## 5. How an AI Agent Should Work with Menus

This section is specifically for behavior of an AI agent that reads or manipulates blueprints.

### 5.1 When reading menus

When inspecting existing blueprints:

1. **Identify Menus**
   - Look for blueprint objects of type `Menu`.
2. **Read structure**
   - For each `Menu`, enumerate:
     - Top-level `Group` and `Action` children
     - Nested `Group` / `Action` trees
3. **Resolve Actions**
   - For each `Action`, understand:
     - The label/icon for UX.
     - The logic it triggers (e.g. which screen or server logic).
4. **Check hosts**
   - Find where each `Menu` is used:
     - Look for `Toolbar`, `Ribbon`, `Menu`, `Sidebar` objects referencing it.

This allows the AI to answer questions like:

- “Where is the customer search accessible in the UI?”
- “Which actions are available in the main toolbar?”
- “What menu entries open screen X?”

### 5.2 When creating or modifying menus

When an AI needs to create or update menus:

1. **Create / reuse Actions**
   - If the functionality already exists (e.g. a screen), either:
     - Reuse an existing `Action` (preferred when semantically the same), or
     - Create a new `Action` with appropriate label/icon/logic for new behavior.
2. **Place Actions into Menus via Groups**
   - Decide which `Menu` is appropriate (e.g. main app menu, module menu).
   - Choose or create a `Group` representing the functional area.
   - Insert the `Action` into that `Group`.
3. **Maintain logical structure**
   - Keep related actions inside the same or neighboring groups.
   - Avoid deep nesting unless it improves clarity.
4. **Respect existing hosts**
   - Ensure that important actions end up in menus that are actually referenced by hosts.
   - If necessary, create or adjust a `Toolbar`, `Ribbon`, `Menu`, or `Sidebar` to reference the new/updated menu.

### 5.3 Do / Don’t Guidelines

**Do:**

- Reuse existing `Action` objects when the underlying behavior is the same.
- Group actions by domain / use case (e.g. “Base Data”, “Sales”, “Administration”).
- Consider how menus are hosted to ensure new functionality is discoverable.

**Don’t:**

- Hard-code menu structure in pro-code; always use the blueprint model.
- Duplicate many nearly-identical actions if they differ only slightly – prefer parameters where appropriate.
- Attach business logic directly to visual host objects; logic belongs to `Action` objects, not to `Toolbar`/`Sidebar` themselves.

---

## 6. Typical Questions This Agent Can Answer

Given this model, an AI agent equipped with this knowledge can:

- List all actions available in a given screen’s toolbar/sidebar.
- Tell which menu/group a specific action belongs to.
- Propose where to add a new action (which menu and group) based on its purpose.
- Refactor menu structures (e.g. split a large menu into multiple groups).
- Help keep menu structure consistent when new screens or features are added.

---

## 7. Summary

- **`Action`** = “something the user can trigger” (label + icon + logic).
- **`Menu`** = container defining the hierarchy of groups and actions.
- **`Group`** = organizational node within a menu, may contain actions and nested groups.
- **Visual hosts** (`Toolbar`, `Ribbon`, `Menu` control, `Sidebar`, …) reference a `Menu` and render its contents.

This separation between **logical structure** (Menu, Group, Action) and **visual host** (Toolbar, Ribbon, Sidebar, …) is central to how navigation and commands are modeled in Build.One.
