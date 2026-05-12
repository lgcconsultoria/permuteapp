# syntax=docker/dockerfile:1.7
# Multi-stage build:
#   1) Flutter SDK builds the web bundle
#   2) Node builds the NestJS API
#   3) Slim runtime joins both, runs migrations + (first-time) seed and serves
#
# Build context must be the repo root (see docker-compose.yml).

############### 1. Flutter web ###############
FROM ghcr.io/cirruslabs/flutter:3.27.4 AS flutter
WORKDIR /flutter
COPY mobile/pubspec.yaml mobile/pubspec.lock ./
RUN flutter pub get
COPY mobile/ ./
# --no-web-resources-cdn bundles CanvasKit locally so the app works offline.
RUN flutter build web --release --no-web-resources-cdn

############### 2. NestJS build ###############
FROM node:20-alpine AS api-build
WORKDIR /app
COPY backend/package.json backend/package-lock.json ./
COPY backend/prisma ./prisma
RUN npm ci
COPY backend/ ./
RUN npx prisma generate && npm run build

############### 3. Runtime ###############
FROM node:20-alpine
WORKDIR /app
ENV NODE_ENV=production

# Install ts-node at runtime so `prisma db seed` can execute seed.ts.
RUN apk add --no-cache tini

COPY --from=api-build /app/dist ./dist
COPY --from=api-build /app/node_modules ./node_modules
COPY --from=api-build /app/prisma ./prisma
COPY --from=api-build /app/package.json ./
COPY --from=flutter   /flutter/build/web ./web

COPY backend/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 3000
ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/docker-entrypoint.sh"]
CMD ["node", "dist/main.js"]
