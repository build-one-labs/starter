FROM node:22-alpine

# Build argurments
ARG BUILD_VERSION=unversioned
ARG BUILD_DATE=undated
ARG BUILD_NAME=starter-app-server-ts
ARG VERSION
ARG BUILD_IMAGE=docker.cloudsmith.io/buildone/repository/starter-appserver-ts:${VERSION}

# Labels
LABEL maintainer="Build.One"
LABEL version=${BUILD_VERSION}
LABEL date=${BUILD_DATE}
LABEL name=${BUILD_NAME}
LABEL image=${BUILD_IMAGE}

ENV NODE_ENV=production

WORKDIR /app

COPY --chown=node:node ./node_modules ./node_modules
COPY --chown=node:node ./*.json ./
COPY --chown=node:node ./dist ./dist/
COPY --chown=node:node ./db_init.sh ./
COPY --chown=node:node ./drizzle ./drizzle/

USER node

CMD ["node", "dist/main.js"]
