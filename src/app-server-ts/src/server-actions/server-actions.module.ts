import { HttpModule } from '@nestjs/axios';
import { Module } from '@nestjs/common';

import { Weather } from './samples/weather';

@Module({
  imports: [HttpModule],
  controllers: [Weather]
})
export class ServerActionsModule {}
