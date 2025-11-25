# Blueprint DSL Knowledge Base - Agent Entry Point

## YOUR MISSION
Generate production-ready Blueprint DSL JSON code based on user requirements.

## CRITICAL FIRST STEPS
1. **Read** ALL files in the blueprint_dsl directory (where this CLAUDE.MD files located)
4. **Study** all files in `blueprint_dsl/samples` - Complete working Blueprint examples

## WHAT IS BLUEPRINT DSL?
Blueprint DSL is JSON metadata that defines user interfaces. The Vanguard rendering engine converts this JSON into working web applications at runtime.

**You generate JSON structures, NOT HTML/CSS/JavaScript.**

```

## GENERATION WORKFLOW
1. **Understand** user requirements
2. **Select** appropriate ObjectTypes
3. **Choose** pattern from `agent_patterns.md` 
4. **Customize** pattern for specific needs
5. **Validate**

## CRITICAL RULES (NEVER VIOLATE)

<!-- CRITICAL_GOVERNANCE -->
- ✅ **NEVER** work with the blueprint .json files, **ALWAYS** use the blueprint mcp tools. the files are only for versioning with git, but the single source of truth for the blueprints is the blueprint database, which you can access via the blueprint mcp.
- ✅ Include all required attributes
- ✅ Generate valid JSON syntax
<!-- /CRITICAL_GOVERNANCE -->

