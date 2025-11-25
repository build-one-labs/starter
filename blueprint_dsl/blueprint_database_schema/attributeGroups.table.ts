import { pgTable, text, timestamp } from 'drizzle-orm/pg-core';

export const attributeGroups = pgTable('attribute_groups', {
  // Primary identifier
  attributeGroupGuid: text('attribute_group_guid').unique().notNull().primaryKey(),

  // Direct mapped fields from JSON
  attributeGroupName: text('attribute_group_name').notNull(),
  attributeGroupDescription: text('attribute_group_description'),

  // Timestamp helpers
  createdAt: timestamp('created_at').defaultNow(),
  updatedAt: timestamp('updated_at').defaultNow()
});
