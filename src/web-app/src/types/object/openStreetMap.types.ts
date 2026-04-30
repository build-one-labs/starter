import type { ObjectAttributes, ObjectBlueprint } from '@buildone/web-core';

export interface OpenStreetMapAttributes extends ObjectAttributes {
  mapName: string;
  mapAddress: string;
  tileServerUrl: string;
  zoomLevel: number;
}

export interface OpenStreetMapBlueprint extends ObjectBlueprint<OpenStreetMapAttributes> {
  objectType: 'openStreetMap';
}
