import { HttpModule } from '@nestjs/axios';
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_GUARD, DiscoveryModule } from '@nestjs/core';
import { DrizzleModule } from './drizzle/drizzle.module';
import { EventsModule } from './events/events.module';
import { B1AuthGuard } from './auth/guard';
import { ApiModule } from './api/api.module';
import { ServerActionsModule } from './server-actions/server-actions.module';
import { RequestContextModule } from './modules/request-context/request-context.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    RequestContextModule,
    DrizzleModule,
    HttpModule,
    EventsModule,
    DiscoveryModule,
    ApiModule,
    ServerActionsModule
  ],
  providers: [
    {
      provide: APP_GUARD,
      useClass: B1AuthGuard
    }
  ]
})
export class AppModule {}
