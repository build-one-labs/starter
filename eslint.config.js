const js = require('@eslint/js');
const ts = require('typescript-eslint');
const eslintPluginPrettierRecommended = require('eslint-plugin-prettier/recommended');
const gts = require('gts');
const vue = require('eslint-plugin-vue');
const json = require('eslint-plugin-json');
const node = require('eslint-plugin-n');

/** @type { import("eslint").Linter.Config[] } */
module.exports = [
  js.configs.recommended,
  ...ts.configs.recommended,
  node.configs['flat/recommended'],
  {
    rules: {
      'n/no-extraneous-import': 'off',
      'n/no-missing-import': 'off'
    }
  },
  eslintPluginPrettierRecommended,
  { rules: gts.rules },
  { ignores: ['dist', '.devcontainer'] },
  { rules: { '@typescript-eslint/no-require-imports': 'off' } },
  {
    files: ['**/*.json'],
    ...json.configs['recommended']
  },
  ...vue.configs['flat/recommended'],
  {
    files: ['*.vue', '**/*.vue'],
    languageOptions: {
      parserOptions: {
        parser: '@typescript-eslint/parser'
      }
    },
    rules: {
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
];
