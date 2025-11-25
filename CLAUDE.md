# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) about this project.
This repository is for developing a business application using the Build.One framework.

The Build.One framework combines a standard development IDE (visual studio code) for conventional coding with a domain specific language (DSL) called blueprint. blueprints are model-based, stored as JSON and at runtime interpreted by a rendering-engine.

## info about the conventional / classic coding

you can find information about the conventional coding in the folder archuitecture_info/. Use that when you need info about architecture, backend and frontend frameworks used, tooling, build process, deployment, documentation, command-line, and similar topcis.

## info about blueprint dsl
The `blueprint_dsl/` directory is a dedicated knowledge base for generating Blueprint DSL JSON that defines UI screens, forms, layouts, grids, events, and data bindings. The Vanguard rendering engine consumes this JSON at runtime.

**ALWAYS** read all the .md files in the blueprint_dsl folder at startup.

## Working with blueprint and objects

- when working with blueprint (sometimes also referred to as objects) ALWAYS use the blueprint MCP server to query and update blueprints. 
- if you receive an error updating a blueprint, check if it is an "ACCESS DENIED" error. if so, stop the update and report the error to the user
- when creating a new blueprint object (also when copying an existing one), make sure that the instances of the newly created object have the correct ObjectMasterGuid. the instances inside the newly created object must have the guid of the newly created object as their ObjectMasterGuid, NOT the guid of the source object. Also make sure that every object you create has its own, unique ObjectMaster GUID.
- IMPORTANT: when copying a blueprint object, NEVER change the original object. ONLY make changes to the object you are newly creating. Use the source object only as a reference/template, do not change it.
- when copying a blueprint object, then create only 1 new object, as a copy of the source object. do NOT create new objects for every instance inside the source object. instead, the newly created object shall have the same instance records as the source, just with the correct new ObjectMasterGuid. That assures that the created copy uses the same objects as instances as the source object, ensuring proper inheritance.
- when the blueprint database returns an error while trying to update a blueprint, check if it is an ACCESS DENIED error. if yes, then stop and report the returned error to the user.
- NEVER use the JSON files directly, ALWWAYS read, query, update blueprint objects via the Blueprint MCP
- when you are querying the blueprint database for samples or best practices, **ONLY** use objects with the module "Swat Samples" (lookup the guid for that module and use it in all your queries where you search for objects to check how something is implemented). other modules belong to old/legacy applications and are not suitable for you to learn and understand blueprint patterns and best practices