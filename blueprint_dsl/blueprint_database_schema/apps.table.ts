import { boolean, pgTable, text, timestamp } from 'drizzle-orm/pg-core';

export const apps = pgTable('apps', {
  // Primary identifier
  productGuid: text('product_guid').unique().notNull().primaryKey(),

  // Direct mapped fields from JSON
  productCode: text('product_code'),
  productDescription: text('product_description'),
  productInstalled: boolean('product_installed'),
  productName: text('product_name'),
  systemOwned: boolean('system_owned'),

  // Timestamp helpers
  createdAt: timestamp('created_at').defaultNow(),
  updatedAt: timestamp('updated_at').defaultNow()
});
