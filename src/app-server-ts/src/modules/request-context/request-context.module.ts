import { Global, Module } from '@nestjs/common';
import { ClsModule, ClsService } from 'nestjs-cls';
import type { Request } from 'express';
import { RequestContext } from './request-context.service';

@Global()
@Module({
  imports: [
    ClsModule.forRoot({
      global: true,
      middleware: {
        mount: true,
        setup: (cls: ClsService, req: Request) => {
          cls.set('req', req);
        }
      }
    })
  ],
  providers: [RequestContext],
  exports: [RequestContext, ClsModule]
})
export class RequestContextModule {}
