import { Module } from '@nestjs/common';
import { TerminusModule } from '@nestjs/terminus';
import { HealthCheckController } from './healthcheck.controller';
import { PostgresHealthCheckIndicator } from './providers/postgres.healthcheck';
import { DrizzleModule } from '@/drizzle/drizzle.module';

@Module({
  imports: [TerminusModule, DrizzleModule],
  controllers: [HealthCheckController],
  providers: [PostgresHealthCheckIndicator]
})
export class HealthCheckModule {}
