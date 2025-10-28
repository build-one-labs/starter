import { Controller, Get } from '@nestjs/common';
import { VersionService } from './version.service';
import { Public } from '@buildone/app-server-tslib';

@Public()
@Controller('/api/version')
export class VersionController {
  constructor(private readonly version: VersionService) {}

  @Get()
  getVersion() {
    return this.version.getInfo();
  }
}
