import { Injectable } from '@nestjs/common';
import { SwatService } from '../swat/swat.service';

@Injectable()
export class RepositoryService {
  constructor(private readonly swatService: SwatService) {}

  getObjectDefinition({ name }: { name: string }) {
    return this.swatService.invokeServerAction({
      name: 'screen/getscreenblueprint',
      payload: { screenName: name, pages: '*', queryParams: {} }
    });
  }
}
