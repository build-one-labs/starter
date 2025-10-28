import { Controller, Get, Param } from '@nestjs/common';
import { DatabaseService } from './database.service';
import { ApiOperation } from '@nestjs/swagger';

@Controller('database')
export class DatabaseController {
  constructor(private readonly databaseService: DatabaseService) {}

  @Get(':table')
  @ApiOperation({ operationId: 'DatabaseGetData' })
  getData(@Param('table') table: string) {
    return this.databaseService.getData({ table });
  }
}
