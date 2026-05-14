import { Module } from '@nestjs/common';
import { RestController } from './rest.controller';
import { CoreApiModule } from '@buildone/app-server-tslib/modules';

@Module({
  controllers: [RestController],
  imports: [CoreApiModule]
})
export class RestModule {}
