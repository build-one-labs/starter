import { HttpException, HttpStatus, Inject, Injectable } from '@nestjs/common';
import { NodePgDatabase } from 'drizzle-orm/node-postgres';
import * as schema from '@/drizzle/schema';
import { DRIZZLE } from '@/drizzle/drizzle.tokens';

@Injectable()
export class DatabaseService {
  constructor(@Inject(DRIZZLE) private conn: NodePgDatabase<typeof schema>) {}

  getData({ table }: { table: string }) {
    const query = this.conn.query[table];
    if (!query) throw new HttpException('Not Found', HttpStatus.NOT_FOUND);
    return this.conn.query[table].findMany({});
  }
}
