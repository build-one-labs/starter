<template>
  <div class="b1-open-street-map">
    <div ref="mapEl" class="b1-osm-canvas" />
  </div>
</template>

<script setup lang="ts">
import { onBeforeUnmount, onMounted, useTemplateRef } from 'vue';

import type { OpenStreetMapBlueprint } from '@/types/object/openStreetMap.types';
import type { ObjectInstance } from '@buildone/web-core';
import 'leaflet/dist/leaflet.css';

type Coords = [number, number];

const props = defineProps<{ instance: ObjectInstance<OpenStreetMapBlueprint> }>();

const mapEl = useTemplateRef<HTMLDivElement>('mapEl');

let leafletMap: import('leaflet').Map | null = null;
let marker: import('leaflet').Marker | null = null;

const DEFAULT_CENTER: Coords = [51.505, -0.09];

function pickCoords(row: Record<string, unknown> | null | undefined): Coords | null {
  if (!row) return null;
  const lat = row.lat ?? row.latitude;
  const lng = row.lng ?? row.lon ?? row.longitude;
  const latNum = typeof lat === 'string' ? Number.parseFloat(lat) : (lat as number);
  const lngNum = typeof lng === 'string' ? Number.parseFloat(lng) : (lng as number);
  return Number.isFinite(latNum) && Number.isFinite(lngNum) ? [latNum, lngNum] : null;
}

async function geocode(address: string): Promise<Coords | null> {
  if (!address) return null;
  const url = `https://nominatim.openstreetmap.org/search?format=json&limit=1&q=${encodeURIComponent(address)}`;
  try {
    const res = await fetch(url, { headers: { Accept: 'application/json' } });
    if (!res.ok) return null;
    const data = (await res.json()) as Array<{ lat: string; lon: string }>;
    const hit = data[0];
    if (!hit) return null;
    return [Number.parseFloat(hit.lat), Number.parseFloat(hit.lon)];
  } catch {
    return null;
  }
}

async function setView(center: Coords) {
  if (!leafletMap) return;
  leafletMap.setView(center, props.instance.attributes.zoomLevel);
  const L = await import('leaflet');
  if (marker) {
    marker.setLatLng(center);
  } else {
    marker = L.marker(center).addTo(leafletMap);
  }
}

onMounted(async () => {
  if (!mapEl.value) return;

  const L = await import('leaflet');
  const { tileServerUrl, zoomLevel, mapAddress } = props.instance.attributes;

  leafletMap = L.map(mapEl.value).setView(DEFAULT_CENTER, zoomLevel);

  L.tileLayer(tileServerUrl, {
    attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
    maxZoom: 19
  }).addTo(leafletMap);

  props.instance.linkStore.subscribe<Record<string, unknown>[]>('DATA', 'dataAvailable', ({ payload }) => {
    const coords = pickCoords(payload?.[0]);
    if (coords) void setView(coords);
  });

  props.instance.linkStore.subscribe<Record<string, unknown>>('DATA', 'cursorChange', ({ payload }) => {
    const coords = pickCoords(payload);
    if (coords) void setView(coords);
  });

  if (mapAddress) {
    const coords = await geocode(mapAddress);
    if (coords) void setView(coords);
  }
});

onBeforeUnmount(() => {
  marker?.remove();
  leafletMap?.remove();
  marker = null;
  leafletMap = null;
});
</script>

<style scoped>
.b1-open-street-map {
  width: 100%;
  height: 100%;
  min-height: 300px;
}
.b1-osm-canvas {
  width: 100%;
  height: 100%;
  min-height: 300px;
}
</style>
