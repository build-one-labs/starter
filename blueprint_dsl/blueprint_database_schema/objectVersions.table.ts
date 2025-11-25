import { integer, jsonb, pgTable, text, timestamp, uuid, varchar } from 'drizzle-orm/pg-core';
import { objects } from './objects.table';

export const objectsVersions = pgTable('objects_versions', {
  // Primary identifier
  versionId: uuid('version_id').primaryKey().defaultRandom(),

  // Reference to the object being tracked
  objectMasterGuid: uuid('object_master_guid')
    .notNull()
    .references(() => objects.objectMasterGuid, { onDelete: 'cascade' }),

  // Version tracking
  versionNumber: integer('version_number').notNull(),

  // Operation type
  operation: varchar('operation', { length: 10 }).notNull().$type<'INSERT' | 'UPDATE' | 'DELETE'>(),

  // Complete record snapshot as JSONB
  recordSnapshot: jsonb('record_snapshot').notNull().$type<Record<string, unknown>>(),

  // Audit fields
  changedBy: text('changed_by'),
  changedAt: timestamp('changed_at').notNull().defaultNow()
});

// Type exports for use in application code
export type ObjectVersion = typeof objectsVersions.$inferSelect;
export type NewObjectVersion = typeof objectsVersions.$inferInsert;
