#!/bin/sh

if [ "${NODE_ENV}" = "development" ]; then
  npm run build
fi

node dist/migrate.js

if [ "${NODE_ENV}" = "development" ]; then
  npm run start:debug
else
  node dist/main.js
fi
