import { Injectable } from '@nestjs/common';
import { InferSelectModel } from 'drizzle-orm';

import { products } from '@/drizzle/schema';

type ProductSelectModel = InferSelectModel<typeof products>;
type ProductCustom = ProductSelectModel & {
  _uiActions: {
    UiAttributes: { FieldName: string; IsAnonymized: boolean }[];
  };
};

@Injectable()
export class ProductEvents {
  onAfterFetch(data: ProductCustom[]) {
    data.forEach((record) => {
      record.description = 'custom calculation: ' + String(Math.random() * 100);

      record._uiActions ??= { UiAttributes: [] };

      // Only apply anonymization for odd IDs
      if (record.productId && Number(record.productId) % 2 !== 0) {
        record.unitPrice = '***********';
        record._uiActions.UiAttributes.push({ FieldName: 'unitPrice', IsAnonymized: true });
      }
    });
  }
}
