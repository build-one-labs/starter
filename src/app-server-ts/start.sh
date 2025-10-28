#!/bin/sh

if [ "${NODE_ENV}" = "development" ]; then
  npm run build
fi

npx drizzle-kit migrate --config dist/drizzle/drizzle.config.js

if [ "${NODE_ENV}" = "development" ]; then
  npm run start:debug
else
  node dist/main.js
fi
