import { Inject, Injectable } from '@nestjs/common';
import { and, asc, desc, eq, gt, gte, ilike, like, lt, lte, ne, not, sql, SQL } from 'drizzle-orm';
import { NodePgDatabase } from 'drizzle-orm/node-postgres';
import * as schema from '@/drizzle/schema';
import { ModuleRef } from '@nestjs/core';
import { DRIZZLE } from '@/drizzle/drizzle.tokens';
import { PgColumn, PgTable } from 'drizzle-orm/pg-core';
import { RepositoryService } from '@/modules/repository/repository.service';

interface DynamicDataEntityDefinition {
  SourceTables: string;
  ServerEventsHandler: string;
}

interface DataOperationPayload {
  entity: string;
}

interface GetDataPayload extends DataOperationPayload {
  queryParams: { akQuery?: string; filter?: string };
}

interface ManipulateDataPayload extends DataOperationPayload {
  data: Record<string, unknown>;
}

interface CommitDataPayload extends DataOperationPayload {
  createdRecords: Record<string, unknown>[];
  updatedRecords: Record<string, unknown>[];
  deletedRecords: Record<string, unknown>[];
}

interface FilterCondition {
  field: string;
  operator: string;
  value: unknown;
}

function getDateFields(table: PgTable): string[] {
  return Object.entries(table)
    .filter(([, col]: [string, PgColumn]) => col?.dataType === 'date' || col?.dataType === 'localDate')
    .map(([name]) => name);
}

function sanitizeDateFields(record: Record<string, unknown>, table: PgTable): Record<string, unknown> {
  const dateFields = getDateFields(table);
  const copy: Record<string, unknown> = { ...record };

  for (const field of dateFields) {
    if (field in copy && copy[field] !== null && copy[field] !== undefined && !(copy[field] instanceof Date)) {
      const date = new Date(copy[field] as string);
      if (!Number.isNaN(date.getTime())) {
        copy[field] = date;
      } else {
        throw new TypeError(`Invalid date for field "${field}": ${copy[field]}`);
      }
    }
  }

  return copy;
}

/**
 * Sanitize an array of records
 */
function sanitizeRecords(records: Record<string, unknown>[], table: PgTable): Record<string, unknown>[] {
  return records.map((record) => sanitizeDateFields(record, table));
}

function addCondition(SourceTable: string, filterData: FilterCondition): SQL {
  const table = schema[SourceTable];
  const { field, operator, value } = filterData;
  switch (operator) {
    case 'neq':
    case 'ne':
    case '<>':
      return ne(table[field], value);
    case 'eq':
    case '=':
      return eq(table[field], value);
    case 'gt':
    case '>':
      return gt(table[field], value);
    case 'lt':
    case '<':
      return lt(table[field], value);
    case 'lte':
    case 'le':
    case '<=':
      return lte(table[field], value);
    case 'gte':
    case 'ge':
    case '>=':
      return gte(table[field], value);
    case 'begins':
    case 'startswith':
      return like(table[field], `${value}%`);
    case 'ends':
    case 'endswith':
      return like(table[field], `%${value}`);
    case 'beginsmatches':
      return ilike(table[field], `${value}%`);
    case 'contains':
      return ilike(table[field], `%${value}%`);
    case 'notcontains':
      return not(ilike(table[field], `%${value}%`));
    case 'matches':
      return ilike(table[field], `${value}`);
    // Add more cases for other operators if needed
    default:
      throw new Error(`Unsupported operator ${operator}`);
  }
}

function getFilterData(SourceTable: string, akQuery, filter): { query?: SQL; orderBy?: SQL } {
  const conditions = akQuery?.filters?.filters?.flatMap((filterData) => {
    if (filterData?.filters) {
      const filterConditions: SQL[] = filterData.filters.map((filterEntry: FilterCondition) => {
        return addCondition(SourceTable, filterEntry);
      });

      return filterConditions;
    } else {
      return [addCondition(SourceTable, filterData)];
    }
  });

  let orderBy: SQL | undefined = undefined;
  if (filter?.orderBy) {
    const [column, order] = filter.orderBy.split(' ');
    if (order === 'desc') {
      orderBy = desc(schema[SourceTable][column]);
    } else {
      orderBy = asc(schema[SourceTable][column]);
    }
  }

  return {
    query: conditions ? and(...conditions) : undefined,
    orderBy
  };
}

@Injectable()
export class DataService {
  constructor(
    private readonly moduleRef: ModuleRef,
    @Inject(DRIZZLE) private readonly conn: NodePgDatabase<typeof schema>,
    private readonly repositoryService: RepositoryService
  ) {}

  async getDataEntity(params: DataOperationPayload): Promise<DynamicDataEntityDefinition> {
    const dataSourceObject = await this.repositoryService.getObjectDefinition({
      name: params.entity
    });
    const dataEntityObject = dataSourceObject.children[0];
    return {
      ServerEventsHandler: dataSourceObject.attributes.ServerEventsHandler,
      SourceTables: dataEntityObject.attributes.SourceTables
    };
  }

  async getData(params: GetDataPayload) {
    const { ServerEventsHandler, SourceTables } = await this.getDataEntity(params);

    const { queryParams } = params;

    const akQuery = queryParams.akQuery ? JSON.parse(queryParams.akQuery) : null;
    const filter = queryParams.filter ? JSON.parse(queryParams.filter) : null;

    const parsedFilter = getFilterData(SourceTables, akQuery, filter);

    // Extract top, skip from queryParams.filter if present
    const top = filter?.top;
    const skip = filter?.skip;
    // Default orderBy to the primary key of the table if not specified, otherwise use the parsed filter orderBy
    const orderBy = parsedFilter.orderBy ?? schema[SourceTables].id;

    const data = await this.conn.query[SourceTables].findMany({
      where: parsedFilter.query,
      limit: top,
      offset: skip,
      orderBy
    });

    if (ServerEventsHandler) {
      const service = this.moduleRef.get(ServerEventsHandler, {
        strict: false
      });
      if (service.onAfterFetch) service.onAfterFetch(data);
    }

    return data;
  }

  async createData(params: ManipulateDataPayload) {
    const { ServerEventsHandler, SourceTables } = await this.getDataEntity(params);
    const data = await this.conn.insert(schema[SourceTables]).values(params.data).returning();

    if (ServerEventsHandler) {
      const service = this.moduleRef.get(ServerEventsHandler, {
        strict: false
      });
      if (service.onAfterCreate) service.onAfterCreate(data);
    }

    return data;
  }

  async updateData(params: ManipulateDataPayload) {
    const { ServerEventsHandler, SourceTables } = await this.getDataEntity(params);
    const data = await this.conn
      .update(schema[SourceTables])
      .set(params.data)
      .where(eq(schema[SourceTables].id, params.data.id))
      .returning();

    if (ServerEventsHandler) {
      const service = this.moduleRef.get(ServerEventsHandler, {
        strict: false
      });
      if (service.onAfterUpdate) service.onAfterUpdate(data);
    }

    return data;
  }

  async deleteData(params: ManipulateDataPayload) {
    const { ServerEventsHandler, SourceTables } = await this.getDataEntity(params);
    const data = await this.conn
      .delete(schema[SourceTables])
      .where(eq(schema[SourceTables].id, params.data.id))
      .returning();

    if (ServerEventsHandler) {
      const service = this.moduleRef.get(ServerEventsHandler, {
        strict: false
      });
      if (service.onAfterDelete) service.onAfterDelete(data);
    }

    return data;
  }

  async commitData(params: CommitDataPayload) {
    const { ServerEventsHandler, SourceTables } = await this.getDataEntity(params);
    const createdRecords = sanitizeRecords(params.createdRecords || [], schema[SourceTables]);
    const updatedRecords = sanitizeRecords(params.updatedRecords || [], schema[SourceTables]);
    const deletedRecords = params.deletedRecords || [];

    const service = ServerEventsHandler
      ? this.moduleRef.get(ServerEventsHandler, {
          strict: false
        })
      : null;

    await this.conn.transaction(async (tx) => {
      if (createdRecords.length > 0) {
        await tx.insert(schema[SourceTables]).values(createdRecords).returning();
        await service?.onAfterCreate?.(createdRecords);
      }

      if (updatedRecords.length > 0) {
        for (const record of updatedRecords) {
          if (record.updatedAt !== undefined) record.updatedAt = sql`now()`;
          await tx.update(schema[SourceTables]).set(record).where(eq(schema[SourceTables].id, record.id)).returning();
          await service?.onAfterUpdate?.(record);
        }
      }

      if (deletedRecords.length > 0) {
        for (const record of deletedRecords) {
          await tx.delete(schema[SourceTables]).where(eq(schema[SourceTables].id, record.id)).returning();
          await service?.onAfterDelete?.(record);
        }
      }
    });
  }
}
