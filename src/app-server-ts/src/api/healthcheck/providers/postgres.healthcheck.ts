import { Inject, Injectable } from '@nestjs/common';
import { HealthIndicatorService } from '@nestjs/terminus';
import { Pool } from 'pg';
import { PG_POOL } from '@/drizzle/drizzle.tokens';

@Injectable()
export class PostgresHealthCheckIndicator {
  constructor(
    @Inject(PG_POOL) private readonly pool: Pool,
    private readonly healthIndicator: HealthIndicatorService
  ) {}

  async isHealthy(key = 'postgres') {
    const indicator = this.healthIndicator.check(key);
    try {
      await this.pool.query('SELECT 1');
      return indicator.up(); // ✅ healthy
    } catch (err) {
      return indicator.down({ message: err?.message ?? 'unknown' }); // ❌ unhealthy
    }
  }
}
