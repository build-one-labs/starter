// https://nuxt.com/docs/api/configuration/nuxt-config
import path from 'path';

export default defineNuxtConfig({
  srcDir: 'src',
  compatibilityDate: '2024-11-01',
  devtools: { enabled: true },
  telemetry: false,
  extends: ['@buildone/web-framework-layer'],
  modules: ['@nuxt/eslint', '@nuxt/image'],
  css: [path.resolve(__dirname, './src/assets/css/custom.css')],
  app: {
    head: {
      title: 'BuildOne Application',
      link: [
        { rel: 'icon', type: 'image/x-icon', href: '/favicon.svg' },
        { rel: 'preconnect', href: 'https://fonts.googleapis.com' },
        { rel: 'preconnect', href: 'https://fonts.gstatic.com', crossorigin: '' },
        {
          rel: 'stylesheet',
          href: 'https://fonts.googleapis.com/css2?family=Antonio:wght@100..700&display=swap'
        }
      ]
    }
  },
  primevue: {
    importTheme: {
      as: 'B1Preset',
      from: path.resolve(__dirname, './src/themes/preset.ts')
    }
  }
});
