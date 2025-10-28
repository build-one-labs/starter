import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';
import { SwatService } from './swat.service';
import { RequestContextModule } from '../request-context/request-context.module';

@Module({
  imports: [HttpModule, RequestContextModule],
  providers: [SwatService],
  exports: [SwatService]
})
export class SwatModule {}
