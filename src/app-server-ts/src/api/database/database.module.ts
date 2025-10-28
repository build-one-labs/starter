import { Module } from '@nestjs/common';
import { DatabaseService } from './database.service';
import { DatabaseController } from './database.controller';
import { DrizzleModule } from '@/drizzle/drizzle.module';

@Module({
  controllers: [DatabaseController],
  imports: [DrizzleModule],
  providers: [DatabaseService]
})
export class DatabaseModule {}
