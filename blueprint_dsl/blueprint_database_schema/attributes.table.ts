import { boolean, jsonb, pgTable, text, timestamp } from 'drizzle-orm/pg-core';

export const attributes = pgTable('attributes', {
  // Primary identifier
  attributeGuid: text('attribute_guid').unique().notNull().primaryKey(),

  // Direct mapped fields from JSON
  attributeGroupGuid: text('attribute_group_guid'),
  attributeLabel: text('attribute_label').unique(),
  technicalName: text('technical_name'),
  attributeDescription: text('attribute_description'),
  runtimeOnly: boolean('runtime_only').default(false),
  virtualProperty: boolean('virtual_property').default(false),
  constantLevel: text('constant_level').default(''),
  lookupType: text('lookup_type').default(''),
  lookupValues: text('lookup_values').default(''),
  propertyType: text('property_type', { enum: ['LOGICAL', 'INTEGER', 'DECIMAL', 'CHARACTER'] }),
  repositoryType: text('repository_type', { enum: ['LOGICAL', 'INTEGER', 'DECIMAL', 'CHARACTER'] }),
  setServiceType: text('set_service_type').default(''),
  propertyOrEvent: boolean('property_or_event').default(true),
  attributeGroupName: text('attribute_group_name'),

  // JSON columns for nested properties
  metaData: jsonb('meta_data').$type<Record<string, unknown>>().default({}),
  metaDataCustom: jsonb('meta_data_custom').$type<Partial<AttributeMetadata>>().default({}),

  // Timestamp helpers
  createdAt: timestamp('created_at').defaultNow(),
  updatedAt: timestamp('updated_at').defaultNow()
});

export interface AttributeMetadata {
  objectTypes: Record<string, Partial<Omit<AttributeMetadata, 'objectTypes'>>>;
  designerOrder: number;
  designerGroup: string;
  designerTags: string;
}
