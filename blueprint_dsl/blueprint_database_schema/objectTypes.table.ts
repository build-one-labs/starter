import { boolean, jsonb, pgTable, text, timestamp, uuid } from 'drizzle-orm/pg-core';

export interface SupportedLinkType {
  linkTypeGuid: string;
  linkSource: boolean;
  linkTarget: boolean;
  supportedLinkGuid: string;
}

export const objectTypes = pgTable('object_types', {
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
  supportedLinkTypes: jsonb('supported_link_types').$type<SupportedLinkType[]>(),
  supportedInstanceTypes: jsonb('supported_instance_types').$type<Array<Record<string, string>>>(),

  // Timestamp helpers
  createdAt: timestamp('created_at').defaultNow(),
  updatedAt: timestamp('updated_at').defaultNow()
});
