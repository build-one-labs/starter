import { Public } from '@buildone/app-server-tslib';
import { Controller, Get } from '@nestjs/common';
import { HealthCheckService, HealthCheck, HttpHealthIndicator } from '@nestjs/terminus';
import { PostgresHealthCheckIndicator } from './providers/postgres.healthcheck';

@Controller('api/healthcheck')
export class HealthCheckController {
  constructor(
    private health: HealthCheckService,
    private http: HttpHealthIndicator,
    private readonly postgres: PostgresHealthCheckIndicator
  ) {}

  @Get()
  @Public()
  @HealthCheck()
  check() {
    return this.health.check([() => this.postgres.isHealthy('postgres')]);
  }
}
