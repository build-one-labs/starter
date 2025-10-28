const mainConfig = require('../../eslint.config');
const globals = require('globals');

/** @type { import("eslint").Linter.Config[] } */
module.exports = [
  ...mainConfig,
  {
    languageOptions: {
      globals: {
        ...globals.node
      }
    }
  }
];
