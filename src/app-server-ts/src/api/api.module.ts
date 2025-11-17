import { Module } from '@nestjs/common';
import { CoreApiModule } from '@buildone/app-server-tslib/modules';

@Module({
  imports: [CoreApiModule],
  exports: [CoreApiModule]
})
export class ApiModule {}
