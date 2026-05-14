import { Module } from '@nestjs/common';
import { Weather } from './samples/weather';
import { PriceCalculation } from './samples/price-calculation';
import { HttpModule } from '@nestjs/axios';

@Module({
  imports: [HttpModule],
  controllers: [Weather, PriceCalculation]
})
export class ServerActionsModule {}
