import { pgTable, text, timestamp } from 'drizzle-orm/pg-core';

export const linkTypes = pgTable('link_type', {
  // Primary identifier
  linkTypeGuid: text('link_type_guid').unique().notNull().primaryKey(),

  // Direct mapped fields from JSON
  linkName: text('link_name'),
  sourceHandshakeMethod: text('source_handshake_method'),
  sourcePropertyName: text('source_property_name'),
  targetHandshakeMethod: text('target_handshake_method'),
  targetPropertyName: text('target_property_name'),

  // Timestamp helpers
  createdAt: timestamp('created_at').defaultNow(),
  updatedAt: timestamp('updated_at').defaultNow()
});
