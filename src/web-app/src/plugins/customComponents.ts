import { registerNewObjectTypeComponent } from '@buildone/web-core';

export default defineNuxtPlugin(() => {
  registerNewObjectTypeComponent('openStreetMap', () => import('@/components/B1OpenStreetMap.vue'));
});
