import { Body, Controller, Delete, Get, Param, Post, Put, Query } from '@nestjs/common';
import { DataService } from './data.service';

@Controller('data')
export class DataController {
  constructor(private readonly dataService: DataService) {}

  @Get(':entity')
  getData(@Param('entity') entity: string, @Query() queryParams: unknown) {
    return this.dataService.getData({ entity, queryParams });
  }

  @Post(':entity')
  createData(@Param('entity') entity: string, @Body() data: Record<string, unknown>) {
    return this.dataService.createData({ entity, data });
  }

  @Put(':entity')
  updateData(@Param('entity') entity: string, @Body() data: Record<string, unknown>) {
    return this.dataService.updateData({ entity, data });
  }

  @Delete(':entity')
  deleteData(@Param('entity') entity: string, @Body() data: Record<string, unknown>) {
    return this.dataService.deleteData({ entity, data });
  }

  @Post(':entity/commit')
  commitData(
    @Param('entity') entity: string,
    @Body()
    body: {
      createdRecords: Record<string, unknown>[];
      updatedRecords: Record<string, unknown>[];
      deletedRecords: Record<string, unknown>[];
    }
  ) {
    return this.dataService.commitData({
      entity,
      createdRecords: body.createdRecords,
      updatedRecords: body.updatedRecords,
      deletedRecords: body.deletedRecords
    });
  }
}
