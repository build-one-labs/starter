import { Provider } from '@nestjs/common';
import { Pool } from 'pg';
import { drizzle } from 'drizzle-orm/node-postgres';
import * as schema from './schema';
import { ConfigService } from '@nestjs/config';
import { DRIZZLE, PG_POOL } from './drizzle.tokens';

export const drizzleProviders: Provider[] = [
  {
    provide: PG_POOL,
    inject: [ConfigService],
    useFactory: (configService: ConfigService) => {
      const connectionString = configService.get<string>('APP_DATABASE_URL');
      return new Pool({
        connectionString,
        ssl: true
      });
    }
  },
  {
    provide: DRIZZLE,
    inject: [PG_POOL],
    useFactory: (pool: Pool) => drizzle(pool, { schema })
  }
];
