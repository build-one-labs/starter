import { sql } from 'drizzle-orm';
import { boolean, jsonb, text, timestamp, uuid, pgView } from 'drizzle-orm/pg-core';

export const objectTypesTreeView = pgView('object_types_tree_view', {
  // Primary identifier
  objectTypeGuid: uuid('object_type_guid').unique().notNull().primaryKey().defaultRandom(),

  // Direct mapped fields from JSON
  classTypeGuid: uuid('class_type_guid').notNull(),
  objectTypeDescription: text('object_type_description').default(''),
  objectTypeName: text('object_type_name').notNull().unique(),
  extendsObjectTypeGuid: uuid('extends_object_type_guid'),
  technicalClassName: text('technical_class_name').default(''),
  containerType: boolean('container_type').default(false),
  storeInstances: text('store_instances').default(''),

  // JSON columns for nested properties
  attributes: jsonb('attributes').$type<Record<string, unknown>>(),
  supportedLinkTypes: jsonb('supported_link_types').$type<Array<Record<string, string>>>(),
  supportedInstanceTypes: jsonb('supported_instance_types').$type<Array<Record<string, string>>>(),

  // Calculated fields
  hasChildren: boolean('has_children').notNull(),

  // Timestamp helpers
  createdAt: timestamp('created_at').defaultNow(),
  updatedAt: timestamp('updated_at').defaultNow()
}).as(
  sql`SELECT id,
    class_type_guid,
    object_type_description,
    object_type_guid,
    object_type_name,
    attributes,
    supported_link_types,
    supported_instance_types,
    created_at,
    updated_at,
    extends_object_type_guid,
    technical_class_name,
    container_type,
    store_instances,
        CASE
            WHEN (EXISTS ( SELECT 1
               FROM object_types ot2
              WHERE ot2.extends_object_type_guid = ot.object_type_guid)) THEN true
            ELSE false
        END AS has_children
   FROM object_types ot`
);
