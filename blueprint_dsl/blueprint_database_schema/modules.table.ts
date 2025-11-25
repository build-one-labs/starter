import { boolean, pgTable, text, timestamp } from 'drizzle-orm/pg-core';

export const modules = pgTable('modules', {
  // Primary identifier
  moduleGuid: text('module_guid').unique().notNull().primaryKey(),

  // Direct mapped fields from JSON
  productGuid: text('product_guid'),
  moduleDataFolder: text('module_data_folder'),
  moduleDescription: text('module_description'),
  moduleName: text('module_name'),
  modulePackage: text('module_package'),
  systemOwned: boolean('system_owned'),

  // Timestamp helpers
  createdAt: timestamp('created_at').defaultNow(),
  updatedAt: timestamp('updated_at').defaultNow()
});
