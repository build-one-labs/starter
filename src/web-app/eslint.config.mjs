import withNuxt from './.nuxt/eslint.config.mjs';
import prettierConfigRecommended from 'eslint-plugin-prettier/recommended';

export default withNuxt([
  prettierConfigRecommended,
  {
    rules: {
      quotes: ['error', 'single'],
      'prettier/prettier': ['error', { singleQuote: true }],
      'vue/multi-word-component-names': 'off',
      '@typescript-eslint/no-explicit-any': 'off',

      'vue/valid-attribute-name': 'off',
      'vue/no-v-html': 'off',
      'vue/require-default-prop': 'off',

      'vue/max-attributes-per-line': 'off',
      'vue/singleline-html-element-content-newline': 'off',
      'vue/multiline-html-element-content-newline': 'off',
      'vue/html-self-closing': [
        'error',
        {
          html: {
            void: 'always',
            normal: 'always',
            component: 'always'
          },
          svg: 'always',
          math: 'always'
        }
      ]
    }
  }
]);
