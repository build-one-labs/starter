import { B1Action, B1Service, B1UserInfo } from '@buildone/app-server-tslib';

@B1Service()
export class {{name}} {
  @B1Action({ description: '{{action.description}}' })
  async {{action.name}}(body: unknown, userInfo: B1UserInfo) {
    return {
      message: 'Service is up and running!',
      timestamp: Date.now(),
      givenParams: body
    };
  }
}

// POST /service/app/server-actions/{{name}}/{{action.name}} body ["some data"]
