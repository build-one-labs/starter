import { Injectable } from '@nestjs/common';
import { InferSelectModel } from 'drizzle-orm';

import { invoices } from '@/drizzle/schema';

type InvoiceSelectModel = InferSelectModel<typeof invoices>;
type InvoiceCustom = InvoiceSelectModel & {
  _uiActions: {
    UiAttributes: { FieldName: string; IsAnonymized: boolean }[];
  };
};

@Injectable()
export class InvoiceEvents {
  onAfterFetch(data: InvoiceCustom[]) {
    data.forEach((invoice) => {
      invoice.totalAmount = 'custom calculation: ' + String(Math.random() * 100);

      invoice._uiActions ??= { UiAttributes: [] };

      // Only apply anonymization for odd IDs
      if (invoice.id && Number(invoice.id) % 2 !== 0) {
        invoice._uiActions.UiAttributes.push({ FieldName: 'customerId', IsAnonymized: true });
      }
    });
  }
}
