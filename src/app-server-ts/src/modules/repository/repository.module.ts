import { Module } from '@nestjs/common';
import { RepositoryService } from './repository.service';
import { SwatModule } from '../swat/swat.module';

@Module({
  imports: [SwatModule],
  providers: [RepositoryService],
  exports: [RepositoryService]
})
export class RepositoryModule {}
