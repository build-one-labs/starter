import { CoreApiModule } from '@buildone/app-server-tslib/modules';
import { Module } from '@nestjs/common';

@Module({
  imports: [CoreApiModule],
  exports: [CoreApiModule]
})
export class ApiModule {}
