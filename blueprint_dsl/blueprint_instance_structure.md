# Blueprint Instance Structure - Critical Rules for AI Agents

> **Purpose:** Essential guidelines for creating and modifying Blueprint object instances
> **Audience:** AI agents working with Blueprint DSL JSON structures
> **Last Updated:** 2025-11-17

---

## Overview

This document captures critical rules and patterns for working with Blueprint instances, particularly focusing on parent-child relationships, required fields, and common pitfalls discovered through real-world debugging.

---

## 1. Nested Instance Structure for Parent-Child Relationships

### ✅ CORRECT: Nested Structure

**Parent objects (like fieldsets) MUST contain their children in a nested `instances` array.**

```json
{
  "instances": [
    {
      "objectName": "SimpleSwatFieldset",
      "instanceName": "Fieldset_BasicInfo",
      "objectMasterGuid": "96bf82d3-2794-2aad-3a14-0242d5a06df7",
      "objectInstanceGuid": "c0c57053-8aae-4668-a248-a02556eb2565",
      "containerObjectMasterGuid": "a44cea51-71bf-40c6-b948-bfbdbd781ebe",
      "attributes": {
        "ROW": 1,
        "COLUMN": 1,
        "LABEL": "Basic Information",
        "collapsed": false
      },
      "instances": [
        {
          "objectName": "productsEntity.productName",
          "instanceName": "productName",
          "objectMasterGuid": "854bfc55-0e5c-81a3-db14-e55318a2d01a",
          "objectInstanceGuid": "f1a00001-0000-0000-0000-000000000001",
          "containerObjectMasterGuid": "a44cea51-71bf-40c6-b948-bfbdbd781ebe",
          "parentInstanceGuid": "c0c57053-8aae-4668-a248-a02556eb2565",
          "parentInstanceName": "Fieldset_BasicInfo",
          "attributes": {
            "ROW": 1,
            "COLUMN": 1,
            "LABEL": "Product Name"
          },
          "instances": []
        }
      ]
    }
  ]
}
```

### ❌ INCORRECT: Flat Structure with Only References

**DO NOT use a flat structure where all instances are siblings with only `parentInstanceGuid` references.**

```json
{
  "instances": [
    {
      "objectName": "SimpleSwatFieldset",
      "instanceName": "Fieldset_BasicInfo",
      "instances": []
    },
    {
      "objectName": "productsEntity.productName",
      "instanceName": "productName",
      "parentInstanceGuid": "c0c57053-8aae-4668-a248-a02556eb2565",
      "instances": []
    }
  ]
}
```

**Why it fails:** The rendering engine expects children to be physically nested in their parent's `instances` array. Flat structures cause children to render as siblings instead of inside their parents.

---

## 2. Required Instance Fields

### All Instances Must Include

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `objectMasterGuid` | UUID | ✅ Yes | References the template/master object |
| `instanceName` | string | ✅ Yes | Unique identifier within the container |
| `objectInstanceGuid` | UUID | ✅ Yes* | Unique GUID for this instance (*required for updates) |
| `containerObjectMasterGuid` | UUID | ✅ Yes* | GUID of the containing object (*required for updates) |
| `attributes` | object | ✅ Yes | Instance-specific configuration |
| `instances` | array | ✅ Yes | Child instances (can be empty `[]`) |

### Child Instances Also Need

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `parentInstanceGuid` | UUID | ✅ Yes | GUID of parent instance |
| `parentInstanceName` | string | ✅ Yes | Name of parent instance |

**Important:** Child instances need **BOTH** physical nesting AND explicit parent references.

---

## 3. Module Requirement

### Critical Rule

**Objects MUST have a valid `module_guid`. The null module causes runtime errors.**

### ❌ Common Error

```json
{
  "moduleGuid": "00000000-0000-0000-0000-000000000000"
}
```

**Error Messages:**
- `Cannot read properties of undefined (reading 'moduleDataFolder')`
- `Cannot read properties of undefined (reading 'moduleName')`

### ✅ Solution

Query an existing working object of the same type and copy its `module_guid`:

```sql
SELECT object_name, module_guid
FROM objects
WHERE object_name = 'similarWorkingObject'
```

Then use that `module_guid` for your new object.

---

## 4. Object Type GUID Validation

### Critical Rule

**The `object_type_guid` must exist in the system and match the actual object type.**

### Common Errors

| Object Type | Error Cause | Solution |
|-------------|-------------|----------|
| SwatForm | Wrong GUID | Use `8c27caef-9edb-f99a-3914-ef7cd4d6ff91` |
| Any | Non-existent GUID | Query: `SELECT object_type_name FROM objects WHERE object_type_guid = 'your-guid'` |

### Verification Query

```sql
SELECT object_name, object_type_guid,
       (SELECT COUNT(*) FROM objects o2
        WHERE o2.object_type_guid = objects.object_type_guid) as guid_usage_count
FROM objects
WHERE object_name = 'yourObject'
```

If `guid_usage_count = 1`, the GUID is likely invalid.

---

## 5. Fieldset-Specific Patterns

### Fieldset Attributes

```json
{
  "objectName": "SimpleSwatFieldset",
  "instanceName": "Fieldset_Name",
  "attributes": {
    "ROW": 1,           // Positioning within parent
    "COLUMN": 1,        // Column position
    "COLUMNS": 1,       // Column span
    "LABEL": "Section Name",  // Header text
    "collapsed": false  // Initial state: false = expanded, true = collapsed
  }
}
```

### Collapse State Control

- `collapsed: false` - Fieldset is initially **expanded** (default for first/primary sections)
- `collapsed: true` - Fieldset is initially **collapsed** (recommended for secondary sections)

---

## 6. Debugging Workflow

When you encounter structure issues:

### Step 1: Find Working Examples

```sql
-- Find forms with fieldsets
SELECT object_name, instances
FROM objects
WHERE instances::text ILIKE '%fieldset%'
  AND object_type_guid = '8c27caef-9edb-f99a-3914-ef7cd4d6ff91'
LIMIT 3
```

### Step 2: Compare Structure Patterns

Look for:
- ✅ Nested `instances` arrays in parent objects
- ✅ All required fields present (`objectMasterGuid`, `objectInstanceGuid`, etc.)
- ✅ Valid `module_guid` (not null module)
- ✅ Valid `object_type_guid`

### Step 3: Replicate Working Pattern

Copy the structural pattern (not the data) from working objects.

---

## 7. Blueprint MCP Best Practices

### Always Use Blueprint MCP Tools

```javascript
// ✅ CORRECT: Use Blueprint MCP
mcp__Blueprint__query_blueprint_using_SQL(...)
mcp__Blueprint__update_blueprint(...)

// ❌ WRONG: Don't work with JSON files directly
// The blueprint database is the source of truth
```

### Query Before Creating

Before creating similar objects:

1. **Find examples:**
   ```sql
   SELECT object_name, object_type_guid, module_guid, instances
   FROM objects
   WHERE object_name ILIKE '%similar%'
   ```

2. **Study structure:** Examine the `instances` array structure

3. **Replicate pattern:** Use the same nesting and field patterns

---

## 8. Common Error Patterns and Solutions

| Error Message | Root Cause | Solution |
|--------------|------------|----------|
| `Cannot read properties of undefined (reading 'moduleDataFolder')` | Invalid or null `module_guid` | Copy `module_guid` from similar working object |
| `Cannot read properties of undefined (reading 'attributes')` | Invalid `object_type_guid` | Query for correct GUID and update |
| Fields render below fieldsets | Flat structure instead of nested | Restructure with nested `instances` arrays |
| `Instance validation failed: missing containerObjectMasterGuid` | Missing required field | Add `containerObjectMasterGuid` to all instances |

---

## 9. Complete Fieldset Form Example

```json
{
  "objectName": "MyStructuredForm",
  "objectMasterGuid": "unique-form-guid",
  "objectTypeGuid": "8c27caef-9edb-f99a-3914-ef7cd4d6ff91",
  "moduleGuid": "ba21da74-0ca7-fda3-8914-0f2ea05dd467",
  "instances": [
    {
      "objectName": "SimpleSwatFieldset",
      "instanceName": "Fieldset_Section1",
      "objectMasterGuid": "96bf82d3-2794-2aad-3a14-0242d5a06df7",
      "objectInstanceGuid": "unique-fieldset-guid",
      "containerObjectMasterGuid": "unique-form-guid",
      "attributes": {
        "ROW": 1,
        "COLUMN": 1,
        "COLUMNS": 1,
        "LABEL": "Section 1",
        "collapsed": false
      },
      "instances": [
        {
          "objectName": "myEntity.field1",
          "instanceName": "field1",
          "objectMasterGuid": "field-template-guid",
          "objectInstanceGuid": "unique-field-instance-guid",
          "containerObjectMasterGuid": "unique-form-guid",
          "parentInstanceGuid": "unique-fieldset-guid",
          "parentInstanceName": "Fieldset_Section1",
          "attributes": {
            "ROW": 1,
            "COLUMN": 1,
            "LABEL": "Field 1"
          },
          "instances": []
        }
      ]
    }
  ]
}
```

---

## 10. Quick Checklist

Before creating/updating Blueprint objects with nested instances:

- [ ] All instances have `objectMasterGuid`
- [ ] All instances have unique `instanceName`
- [ ] All instances have `objectInstanceGuid` (for updates)
- [ ] All instances have `containerObjectMasterGuid` (for updates)
- [ ] All instances have `instances` array (even if empty)
- [ ] Child instances are **nested** in parent's `instances` array
- [ ] Child instances have `parentInstanceGuid` and `parentInstanceName`
- [ ] Object has valid (non-null) `module_guid`
- [ ] Object has valid `object_type_guid`
- [ ] Fieldsets have `collapsed` attribute set appropriately

---

## Related Documentation

- `blueprint_dsl/CLAUDE.md` - Main agent entry point
- `blueprint_dsl/screens.md` - Screen patterns and layouts
- `blueprint_dsl/blueprint-model.md` - Core Blueprint concepts
- `blueprint_dsl/blueprint_database_schema/` - Database schema reference
