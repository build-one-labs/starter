import { Injectable } from '@nestjs/common';
import { Request } from 'express';
import { ClsService } from 'nestjs-cls';

@Injectable()
export class RequestContext {
  constructor(private readonly cls: ClsService) {}

  get req() {
    return this.cls.get('req');
  }
  set req(v: Request | undefined) {
    this.cls.set('req', v);
  }

  get token() {
    return this.req.cookies?.['__Secure-b1.session_token'];
  }
  get user() {
    return this.req.user;
  }
  get session() {
    return 'session' in this.req ? this.req.session : undefined;
  }
  get headers() {
    return this.req.headers;
  }
}
