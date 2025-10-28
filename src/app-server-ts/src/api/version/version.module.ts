import { Module } from '@nestjs/common';
import { VersionController } from './version.controller';
import { VersionService } from './version.service';
import { DrizzleModule } from '@/drizzle/drizzle.module';
import { PostgresVersionChecker } from './providers/postgres.version';

@Module({
  imports: [DrizzleModule],
  controllers: [VersionController],
  providers: [VersionService, PostgresVersionChecker],
  exports: [VersionService]
})
export class VersionModule {}
