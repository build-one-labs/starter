import { Module } from '@nestjs/common';
import { DataService } from './data.service';
import { DataController } from './data.controller';
import { DrizzleModule } from '@/drizzle/drizzle.module';
import { RepositoryModule } from '@/modules/repository/repository.module';

@Module({
  controllers: [DataController],
  imports: [DrizzleModule, RepositoryModule],
  providers: [DataService]
})
export class DataModule {}
