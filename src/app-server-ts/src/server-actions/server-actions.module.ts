import { Module } from '@nestjs/common';
import { Weather } from './samples/weather';
import { HttpModule } from '@nestjs/axios';

@Module({
  imports: [HttpModule],
  controllers: [Weather]
})
export class ServerActionsModule {}
