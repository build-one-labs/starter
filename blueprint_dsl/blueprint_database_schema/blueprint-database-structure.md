# Build.One Blueprint Database Schema – Agent Reference

> **Audience:** AI coding / refactoring agents working with Build.One blueprints  
> **Goal:** Explain how the actual blueprint database schema looks like, so you can build correct and efficient SQL statements to query and maintain blueprint objects.

---

## Where to find information about the blueprint database schema

You can find the drizzle schema for the blueprint database as *.ts files in the same folder as this file.
Those .ts files are used by drizzle to create the actual schema in the blueprint postgres database.
Always make sure that your SQL queries are valid against the schema information defined in those .ts files.
**never** make up tables or fields, if somewthing is not exist in those .ts files, it does not exist.

## Blueprint MCP Query Performance Optimization

**CRITICAL: Always optimize Blueprint database queries for performance.**

The blueprint database has been optimized with comprehensive indexes including trigram indexes for text search, GIN indexes for JSONB queries, and foreign key indexes. However, query patterns significantly impact performance.

### Query Pattern Guidelines

**1. Exact Match Queries (FASTEST - ~5-50ms)**

When you know the exact object name, use exact match:
```sql
WHERE object_name = 'exactObjectName'
```

**2. Prefix Pattern Queries (RECOMMENDED - ~300-400ms)**

When searching by name prefix (user knows how the name starts), use prefix pattern:
```sql
-- CORRECT: Use prefix pattern
WHERE object_name ILIKE 'invoice%'

-- WRONG: Do NOT use contains pattern
WHERE object_name ILIKE '%invoice%search%'
```

**Performance difference:** Prefix patterns are **17x faster** than contains patterns (350ms vs 6000ms).

**3. Contains Pattern Queries (SLOW - ~5-6 seconds)**

Only use contains patterns when absolutely necessary (rare fuzzy search):
```sql
-- Use only when user needs fuzzy search across entire name (e.g. when you already did a search with exact match or prefix match, and did not get a result)
WHERE object_name ILIKE '%pattern%'
```

### Query Strategy Decision Tree

```
User knows exact name?
  YES → Use: WHERE object_name = 'exactName'         [~5ms]

User knows name prefix/start?
  YES → Use: WHERE object_name ILIKE 'prefix%'       [~350ms]

User needs fuzzy search (or prevvious search did return an empty result)?
  YES → Use: WHERE object_name ILIKE '%pattern%'     [~6000ms]
       → Warn user about slower performance
```

### Case Sensitivity

- **ILIKE** - Case-insensitive (recommended for user-facing searches)
- **LIKE** - Case-sensitive (slightly faster, ~10% improvement)
- Choose ILIKE for better user experience unless case matters

### Multiple Pattern Search

When searching for multiple possible prefixes:
```sql
-- CORRECT: Use OR with prefix patterns
WHERE object_name ILIKE 'invoice%' OR object_name ILIKE 'customer%'

-- WRONG: Avoid contains with OR
WHERE object_name ILIKE '%invoice%' OR object_name ILIKE '%customer%'
```

### Performance Expectations

| Query Type | Pattern | Expected Time | Use When |
|------------|---------|---------------|----------|
| Exact match | `= 'name'` | 5-50ms | User provides exact name |
| Prefix search | `ILIKE 'prefix%'` | 300-400ms | User knows name start (RECOMMENDED) |
| Contains search | `ILIKE '%pattern%'` | 5-6 seconds | Fuzzy search only (RARE) |

### Examples

**CORRECT Usage:**
```sql
-- User searching for invoice-related objects
SELECT * FROM objects WHERE object_name ILIKE 'invoice%';

-- User searching for customer forms
SELECT * FROM objects WHERE object_name ILIKE 'customer%';

-- User knows exact name
SELECT * FROM objects WHERE object_name = 'invoiceSearch';
```

**INCORRECT Usage (Avoid):**
```sql
-- TOO SLOW: Contains pattern on both sides
SELECT * FROM objects WHERE object_name ILIKE '%invoice%search%';

-- TOO SLOW: Multiple contains patterns
SELECT * FROM objects WHERE object_name ILIKE '%invoice%' OR object_name ILIKE '%search%';
```

### When to Measure Query Performance

- Always measure and report execution time when requested by the user
- Use timestamp measurements before and after each Blueprint MCP query
- Report times in seconds with context about what was queried

