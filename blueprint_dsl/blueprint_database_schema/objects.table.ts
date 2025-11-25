import { boolean, jsonb, pgTable, text, timestamp, uuid } from 'drizzle-orm/pg-core';
import { Instance, Link, Page } from './mock.tables';

export const objects = pgTable('objects', {
  // Primary identifier
  objectMasterGuid: uuid('object_master_guid').unique().notNull().primaryKey().defaultRandom(),

  // Direct mapped fields from JSON
  objectName: text('object_name').notNull().unique(),
  moduleGuid: uuid('module_guid'),
  objectDescription: text('object_description'),
  objectTypeGuid: uuid('object_type_guid'),
  templateObject: boolean('template_object').default(false),
  runnableFromMenu: boolean('runnable_from_menu').default(false),
  staticObject: boolean('static_object').default(false),
  objectPackage: text('object_package').default(''),
  objectExtension: text('object_extension').default(''),
  deploymentType: text('deployment_type').default(''),

  // JSON columns for nested properties
  attributes: jsonb('attributes').$type<Record<string, unknown>>(),
  instances: jsonb('instances').$type<Array<Instance>>(),
  pages: jsonb('pages').$type<Array<Page>>(),
  links: jsonb('links').$type<Array<Link>>(),

  // Timestamp helpers
  createdAt: timestamp('created_at').defaultNow(),
  updatedAt: timestamp('updated_at').defaultNow()
});
