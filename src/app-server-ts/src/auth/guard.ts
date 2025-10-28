import { Inject, Injectable } from '@nestjs/common';
import type { CanActivate, ExecutionContext } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { APIError, type getSession } from 'better-auth/api';
import { fromNodeHeaders } from 'better-auth/node';

import { createAuthClient } from 'better-auth/client';
const authClient = createAuthClient({
  baseURL: 'http://swat_app_server_ts:3000/'
});

export type UserSession = NonNullable<Awaited<ReturnType<ReturnType<typeof getSession>>>>;

@Injectable()
export class B1AuthGuard implements CanActivate {
  constructor(
    @Inject(Reflector)
    private readonly reflector: Reflector
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();

    const { data: session } = await authClient.getSession(
      {},
      {
        headers: fromNodeHeaders(request.headers)
      }
    );

    request.session = session;
    request.user = session?.user ?? null;

    const isPublic = this.reflector.getAllAndOverride<boolean>('PUBLIC', [context.getHandler(), context.getClass()]);

    if (isPublic) return true;

    const isOptional = this.reflector.getAllAndOverride<boolean>('OPTIONAL', [
      context.getHandler(),
      context.getClass()
    ]);

    if (isOptional && !session) return true;

    if (!session)
      throw new APIError(401, {
        code: 'UNAUTHORIZED',
        message: 'Unauthorized'
      });

    return true;
  }
}
