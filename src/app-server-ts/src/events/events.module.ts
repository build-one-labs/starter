import { Module, Global } from '@nestjs/common';

import { InvoiceEvents } from './invoice.events';
import { ProductEvents } from './products.events';

@Global()
@Module({
  providers: [
    {
      provide: 'InvoiceEvents',
      useClass: InvoiceEvents
    },
    {
      provide: 'ProductEvents',
      useClass: ProductEvents
    }
  ]
})
export class EventsModule {}
