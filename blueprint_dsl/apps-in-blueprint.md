# Apps in Blueprint Database

## Overview
A Build.One application is represented in the blueprint database by **two related records**:
1. An app record in the `apps` table
2. A corresponding blueprint object of type `SwatApp` in the `objects` table

## Key Relationship
**The link between apps and blueprints is:**
```
apps.product_code = objects.object_name
```
This is NOT through the module hierarchy, but a direct name-based relationship.

## Apps Table Structure
- **product_guid** (text, primary key) - Unique identifier for the app
- **product_code** (text) - Code/identifier that links to blueprint object name
- **product_name** (text) - Display name
- **product_description** (text) - Description
- **product_installed** (boolean) - Installation status
- **system_owned** (boolean) - System vs custom app flag

## SwatApp Blueprint Objects
- **Object Type**: SwatApp (object_type_guid: `88bc46ce-f409-269d-aa14-beb3a897edab`)
- **Required**: Each app should have exactly ONE non-template SwatApp object
- **Naming**: The object_name must match the app's product_code

## SwatApp Attributes
Key attributes that define app behavior:
- **startupScreen** - The initial screen launched when app starts
- **mainMenuCode** - Reference to the main menu object
- **baseLayout** - Layout template (e.g., "taskbarMainLayout")
- **loginScreen** - Custom login screen (optional)
- **defaultTheme** - Theme configuration
- **backgroundImage** - Background image path
- **translationNamespaces** - i18n namespaces

## Validation Query
```sql
-- Check apps with matching blueprints
SELECT
    a.product_code,
    a.product_name,
    o.object_name,
    CASE
        WHEN o.object_name IS NULL THEN 'Missing Blueprint'
        WHEN a.product_code = o.object_name THEN 'Matched'
        ELSE 'Mismatch'
    END as status
FROM apps a
LEFT JOIN objects o ON a.product_code = o.object_name
    AND o.object_type_guid::text = '88bc46ce-f409-269d-aa14-beb3a897edab'
    AND o.template_object = false;
```

## Validation Rules
1. Each app (product_code) must have a matching SwatApp object (object_name)
2. Each non-template SwatApp object should have a matching app
3. Template objects (template_object = true) should be excluded from validation
4. Look for:
   - Apps without blueprints (missing blueprint objects)
   - Orphaned blueprints (blueprint objects without matching apps)

## Module Relationship
- Apps have modules: `apps.product_guid = modules.product_guid`
- Objects belong to modules: `objects.module_guid = modules.module_guid`
- SwatApp objects are typically stored in app-specific modules

## Key Insight
The product_code/object_name relationship is the primary link, NOT the module hierarchy. Always validate using this name-based relationship.

# The UI elements that make up an App for the User

## 2. Initial Screen Attribute

- The app object type includes an `initialScreen` attribute.
- This attribute specifies the first screen that should be loaded when the app starts.
- The initial screen usually provides a main menu for the application, which acts as the starting point for a user.

---

## 3. Default Initial Screen: SidebarMenuScreen

- By default, Build.One provides a template screen named **SidebarMenuScreen**.
- This screen includes a sidebar component with a `menu` attribute that defines the initial menu the application should display.
- in addition it contains a screencontainer object. this acts as the container for screens that are rendered when the user selects a menu-entry in the sidebar.
- usually those screens act as a search screen, showing matching records for the menu-item. those search screens (in build.one terms sometimes called "Desktops") then provide a way to open the maintenance-screen for a record, or to launch screens to create new records

---

## 4. Sample Menu: SampleAppMainMenu

- Build.One ships a sample menu that is typically used by the `SidebarMenuScreen`.
- The name of this menu is **SampleAppMainMenu**.
- This sample menu defines the default initial menu structure for an application.

---

Use this information to correctly understand how apps are identified and initialized in the blueprint, and how the default initial UI (screen + menu) is typically configured.


## steps when creating a new application:

1. create a menu for the application by copying an existing menu, e.g. the SampleAppMainMenu
2. create a record in the apps table and create a corresponding blueprint App object.
3. create a main screen for the application by copying the SidebarMenuScreen, and set the menu to be used in that screen to the menu you created in step 1
4. use the newly created main screen as the initialScreen in the app object you created in step 2


**important**
When creating a new app, create a new screen to use as the initialScreen for the app, and create a new menu to use as the main menu of the app. Unless told otherwise by the user, always use the SideBarMenuScreen as the source for the new initial screen, and use the SampleAppMainMenu as the source for the menu. 