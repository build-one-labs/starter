import { Module } from '@nestjs/common';
import { drizzleProviders } from './drizzle.providers';
import { DrizzleController } from './drizzle.controller';

@Module({
  controllers: [DrizzleController],
  providers: [...drizzleProviders],
  exports: [...drizzleProviders]
})
export class DrizzleModule {}
