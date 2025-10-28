import { Module } from '@nestjs/common';
import { DatabaseModule } from './database/database.module';
import { DataModule } from './data/data.module';
import { HealthCheckModule } from './healthcheck/healthcheck.module';
import { VersionModule } from './version/version.module';

@Module({
  imports: [DatabaseModule, DataModule, HealthCheckModule, VersionModule],
  exports: [DatabaseModule, DataModule, HealthCheckModule, VersionModule]
})
export class ApiModule {}
