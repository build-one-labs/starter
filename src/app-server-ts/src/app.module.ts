import { HttpModule } from '@nestjs/axios';
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_GUARD, DiscoveryModule } from '@nestjs/core';
import { EventsModule } from './events/events.module';
import { ApiModule } from './api/api.module';
import { ServerActionsModule } from './server-actions/server-actions.module';
import { RequestContextModule } from '@buildone/app-server-tslib/modules';
import { B1AuthGuard } from '@buildone/app-server-tslib/auth';
import { DrizzleModule } from '@buildone/app-server-tslib/drizzle';
import * as schema from './drizzle/schema';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    DrizzleModule.forRoot({
      global: true,
      schema,
      database: {
        configKey: 'APP_DATABASE_URL',
        ssl: true
      }
    }),
    RequestContextModule,
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
