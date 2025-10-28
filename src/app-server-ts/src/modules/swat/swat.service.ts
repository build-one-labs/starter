import * as qs from 'qs';
import { HttpService } from '@nestjs/axios';
import { Injectable } from '@nestjs/common';
import { handleExternalHttpRequest } from '@/utils/http';
import { RequestContext } from '../request-context/request-context.service';

@Injectable()
export class SwatService {
  protected swatUrl = 'http://swat_app_server_ts:3000';

  constructor(
    private readonly httpService: HttpService,
    protected readonly ctx: RequestContext
  ) {}

  public async invokeServerAction({ name, payload }: { name: string; payload: unknown }) {
    const request = this.httpService.post(`${this.swatUrl}/server-actions/${name}`, payload, {
      headers: { Cookie: `__Secure-b1.session_token=${this.ctx.token};` },
      paramsSerializer: (params) => qs.stringify(params, { arrayFormat: 'brackets' })
    });
    const { data } = await handleExternalHttpRequest(request);
    return data;
  }
}
