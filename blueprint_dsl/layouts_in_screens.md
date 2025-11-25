# Build.One Layouts — agent.md
_Last updated: 2025-11-22_

This document teaches an AI agent how to understand, select, and emit Build.One **screen Layouts**. It is **authoritative** for the fixed set of layouts currently supported.

---

## 1) Concepts & Naming

- A **Layout** places a fixed number of **Panels** on a screen.
- **Panels** are containers for Build.One UI components (tables/grids, forms, charts, etc.).
- Panels are named with **single letters**: `a`, `b`, `c`, …
- Panels are separated by horizontal/vertical **splitter bars**; the renderer handles dragging and persistence of split sizes.
- A Layout has a unique **Name**: `<count><letter>`
  - `<count>` = number of panels
  - `<letter>` ≈ mnemonic of the splitter silhouette (T, U, E, W, etc.)

### Supported Layouts (fixed set)

- `1C`, `2E`, `2U`, `3E`, `3W`, `3T`

> If you need a layout beyond this list, do **not** invent a new one; request a product update instead.

---

## 2) Visual Definitions (ASCII)

```
1C  (one full-area panel)           2E  (vertical stack)               2U  (horizontal split)
+-----------+                       +-----------+                      +-----+-----+
|     a     |                       |     a     |                      |  a  |  b  |
+-----------+                       +-----------+                      +-----+-----+
                                    |     b     |
                                    +-----------+

3E  (three stacked vertically)      3W  (three stacked horizontally)   3T  (T-shape, a large pabel on top, 2 smaller ones below)
+-----------+                       +----+----+----+                   +-----------+
|     a     |                       | a  | b  | c  |                   |     a     |
+-----------+                       +----+----+----+                   +-----+-----+
|     b     |                                                           |  b  |  c  |
+-----------+                                                           +-----+-----+
|     c     |
+-----------+
```

---

## 3) Panel Semantics & Typical Uses

- **Master–Detail (horizontal)** → **`2U`** (left=master table in `a`, right=detail form in `b`).
- **Master–Detail (vertical, stacked)** → **`2E`** (top table `a`, bottom form `b`) for narrow screens or long forms.
- **Dashboard (three columns)** → **`3W`** for 3 independent widgets/panels.
- **Process (top header + two work areas)** → **`3T`** with `a` as banner/filters and `b`/`c` as work panels.
- **Document-centric** → **`1C`** for a single large component (page/form/chart).
- **Sequential drill-down** → **`3E`** for vertically staged steps or stacked summaries.

> Rule of thumb: prefer **`2U`** for classic table+form master–detail. Switch to **`2E`** when horizontal space is tight or the form is tall.

---

## 4) Machine-Readable Catalog

Use the following spec when generating UI or reasoning about placements. This is layout-agnostic to framework (usable in Nuxt/Vue host or other UIs).

```json
{
  "layouts": [
    {
      "name": "1C",
      "panels": ["a"],
      "areas": [["a"]]
    },
    {
      "name": "2E",
      "panels": ["a","b"],
      "areas": [["a"], ["b"]]
    },
    {
      "name": "2U",
      "panels": ["a","b"],
      "areas": [["a","b"]]
    },
    {
      "name": "3E",
      "panels": ["a","b","c"],
      "areas": [["a"], ["b"], ["c"]]
    },
    {
      "name": "3W",
      "panels": ["a","b","c"],
      "areas": [["a","b","c"]]
    },
    {
      "name": "3T",
      "panels": ["a","b","c"],
      "areas": [["a","a"], ["b","c"]]
    }
  ]
}
```

**Notes**
- `areas` is a matrix describing rows; each string is a panel area.
- Splitter positions are host responsibilities; persist sizes outside this catalog (e.g., in per-screen settings).

---

## 5) Blueprint Authoring Rules (for agents)

When creating or modifying a **Screen** blueprint:

1. **Choose `layout`** from the fixed set: `1C`, `2E`, `2U`, `3E`, `3W`, `3T`.
2. **Create panels** `a..` per the chosen layout **only** (do not add extra panels).
3. **Place components** inside panels by panel letter.
4. **Do not render splitters yourself**; the renderer does.

### Example: Screen blueprint JSON (minimal)

```json
{
  "deploymentType": "",
  "moduleGuid": "ba21da74-0ca7-fda3-8914-0f2ea05dd467",
  "objectDescription": "Products search screen, showing a datalist and a form side by side",
  "objectExtension": "",
  "objectMasterGuid": "abe574ad-8df4-ec9b-db14-eb5078b89009",
  "objectName": "productsSearch",
  "objectPackage": "",
  "objectTypeGuid": "8c27caef-9edb-f99a-3914-ec7c1c00decc",
  "runnableFromMenu": false,
  "staticObject": false,
  "templateObject": false,
  "attributes": {
    "isModal": false,
    "LayoutOptions": "2U"
  },
  "instances": [
    {
      "containerObjectMasterGuid": "abe574ad-8df4-ec9b-db14-eb5078b89009",
      "instanceName": "productsDSO",
      "objectInstanceGuid": "17aff416-790b-4c0a-95be-04ffd44a50a0",
      "objectMasterGuid": "854bfc55-0e5c-81a3-db14-e753b8f1fad0",
      "objectName": "productsDSO",
      "objectSequence": 1,
      "attributes": {},
      "instances": []
    },
    {
      "containerObjectMasterGuid": "abe574ad-8df4-ec9b-db14-eb5078b89009",
      "instanceName": "productsForm",
      "layoutPosition": "b",
      "objectInstanceGuid": "faa85de0-07d2-4f64-a8ef-a53afce4dca0",
      "objectMasterGuid": "854bfc55-0e5c-81a3-db14-ee53f8f2d549",
      "objectName": "productsForm",
      "objectSequence": 3,
      "parentInstanceGuid": "",
      "attributes": {},
      "instances": []
    },
    {
      "containerObjectMasterGuid": "abe574ad-8df4-ec9b-db14-eb5078b89009",
      "instanceName": "productsGrid",
      "layoutPosition": "a",
      "objectInstanceGuid": "27254178-b30b-473d-949f-8293ec344a7c",
      "objectMasterGuid": "854bfc55-0e5c-81a3-db14-ec53c0353555",
      "objectName": "productsGrid",
      "objectSequence": 4,
      "parentInstanceGuid": "",
      "attributes": {
        "panelMenu": "gridFilterDynSelect,gridPanelStandard,VanguardGridPanelMenu#NoDropDown"
      },
      "instances": []
    }
  ],
  "links": [
    {
      "containerObjectMasterGuid": "abe574ad-8df4-ec9b-db14-eb5078b89009",
      "linkGuid": "6becb10f-bf68-437c-adc6-f9115cef89c2",
      "linkName": "PrimarySdo",
      "linkTypeGuid": "f52235a4-c120-2490-3814-9c2915819244",
      "sourceInstanceName": "",
      "targetInstanceName": "productsDSO",
      "targetObjectInstanceGuid": "17aff416-790b-4c0a-95be-04ffd44a50a0"
    },
    {
      "containerObjectMasterGuid": "abe574ad-8df4-ec9b-db14-eb5078b89009",
      "linkGuid": "f78eebaf-ac35-463a-b11f-6b1b9af42897",
      "linkName": "Data",
      "linkTypeGuid": "d37727fb-24ff-7ea3-0e14-a5d9d8526f38",
      "sourceInstanceName": "productsDSO",
      "sourceObjectInstanceGuid": "17aff416-790b-4c0a-95be-04ffd44a50a0",
      "targetInstanceName": "productsForm",
      "targetObjectInstanceGuid": "faa85de0-07d2-4f64-a8ef-a53afce4dca0"
    },
    {
      "containerObjectMasterGuid": "abe574ad-8df4-ec9b-db14-eb5078b89009",
      "linkGuid": "9114d625-23d9-4054-be22-ab367a913930",
      "linkName": "Data",
      "linkTypeGuid": "d37727fb-24ff-7ea3-0e14-a5d9d8526f38",
      "sourceInstanceName": "productsDSO",
      "sourceObjectInstanceGuid": "17aff416-790b-4c0a-95be-04ffd44a50a0",
      "targetInstanceName": "productsGrid",
      "targetObjectInstanceGuid": "27254178-b30b-473d-949f-8293ec344a7c"
    }
  ],
  "pages": []
}
```

**Agent behavior**  
- If the form is very tall or the viewport will be narrow, prefer `"LayoutOptions": "2E"` and keep the same bindings.

---


## 7) Decision Guide (for agents)

- **Table + Detail Form?** → `2U` (or `2E` if vertical layout is preferable).
- **3 independent widgets?** → `3W`.
- **Top banner/filters + two work zones?** → `3T`.
- **Single immersive component?** → `1C`.
- **Three staged sections?** → `3E`.

If uncertain between `2U` and `2E`:
- Prefer **`2U`** when landscape space is sufficient and simultaneous visibility is key.
- Prefer **`2E`** on narrow viewports or when forms are tall.

---

## 8) Validation Rules (agents must enforce)

- The chosen layout **must** be one of the fixed set.
- The number of panels **must equal** the layout definition.
- Panel names **must** be consecutive letters starting at `a` without gaps.
- Do **not** rename panels based on content (panel letters are positional).
- Do **not** introduce ad-hoc splitter schemes or nested layouts inside panels (compose screens instead).

---


## 10) Quick Reference

- **Fixed layouts:** `1C`, `2E`, `2U`, `3E`, `3W`, `3T`
- **Panel letters:** `a`, `b`, `c` (count depends on layout)
- **Master–Detail default:** `2U (a=grid, b=form)`
- **Narrow/tall alternative:** `2E`
- **Three columns:** `3W`
- **T-shape:** `3T`
- **Single pane:** `1C`
- **Three stacked:** `3E`

---


## 11) Changelog

- 2025-11-22: Initial version aligned to fixed Build.One layout catalog.
