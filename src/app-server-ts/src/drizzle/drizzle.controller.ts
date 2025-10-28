import { Controller, Get, Inject, Param } from '@nestjs/common';
import { getTableName } from 'drizzle-orm';
import { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { getTableConfig } from 'drizzle-orm/pg-core';
import { DRIZZLE } from './drizzle.tokens';
import * as drizzleSchema from '@/drizzle/schema';

@Controller('drizzle')
export class DrizzleController {
  constructor(@Inject(DRIZZLE) private conn: NodePgDatabase<typeof drizzleSchema>) {}

  @Get('schema')
  async getSchema() {
    return Object.keys(drizzleSchema);
  }

  @Get('schema/:schemaName')
  async getSchemaByName(@Param('schemaName') schemaName: string) {
    const schema = drizzleSchema[schemaName];

    const config = getTableConfig(schema);

    return {
      name: getTableName(schema),
      config: {
        schema: config.schema,
        columns: config.columns.map((col) => {
          return {
            name: col.name,
            columnType: col.columnType,
            dataType: col.dataType,
            default: col.default,
            generated: col.generated,
            generatedIdentity: col.generatedIdentity,
            hasDefault: col.hasDefault,
            isUnique: col.isUnique,
            keyAsName: col.keyAsName,
            notNull: col.notNull,
            primary: col.primary,
            uniqueName: col.uniqueName,
            uniqueType: col.uniqueType
          };
        })
      }
    };
  }
}
