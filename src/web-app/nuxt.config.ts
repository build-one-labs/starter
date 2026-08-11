// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  // Nuxt's default `.nuxt`, kept overridable so a build can be pointed away
  // from a running dev server, which restarts if anything clears the directory
  // it is watching: `NUXT_BUILD_DIR=.nuxt-build yarn build`. Nothing sets it by
  // default. Restated here so the escape hatch does not depend on which layer
  // version this app pins — see the framework layer's nuxt.config.ts.
  buildDir: process.env.NUXT_BUILD_DIR || '.nuxt',
  srcDir: 'src',
  compatibilityDate: '2024-11-01',
  devtools: { enabled: true },
  telemetry: false,
  extends: ['@buildone/web-framework-layer'],
  modules: ['@nuxt/eslint', '@nuxt/image'],
  app: {
    head: {
      title: 'BuildOne Application',
      link: [{ rel: 'icon', type: 'image/x-icon', href: '/favicon.svg' }]
    }
  }
});
