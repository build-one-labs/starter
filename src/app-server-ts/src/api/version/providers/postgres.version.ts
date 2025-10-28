import { Inject, Injectable } from '@nestjs/common';
import { Pool } from 'pg';
import { PG_POOL } from '@/drizzle/drizzle.tokens';

@Injectable()
export class PostgresVersionChecker {
  constructor(@Inject(PG_POOL) private readonly pool: Pool) {}

  async getVersion() {
    const result = await this.pool.query('SHOW server_version;');
    return result.rows[0].server_version;
  }
}
