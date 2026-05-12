# Multi-stage build:
#   1) Flutter SDK builds the web bundle
#   2) Node builds the NestJS API
#   3) Slim runtime joins both, runs migrations + (first-time) seed and serves
#
# Build context must be the repo root (see docker-compose.yml).

############### 1. Flutter web ###############
FROM instrumentisto/flutter:3.27 AS flutter
WORKDIR /flutter
COPY mobile/pubspec.yaml mobile/pubspec.lock ./
RUN flutter pub get
COPY mobile/ ./
# --no-web-resources-cdn bundles CanvasKit locally so the app works offline.
RUN flutter build web --release --no-web-resources-cdn

############### 2. NestJS build ###############
FROM node:20-slim AS api-build
RUN apt-get update && apt-get install -y --no-install-recommends openssl ca-certificates \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY backend/package.json backend/package-lock.json ./
COPY backend/prisma ./prisma
RUN npm ci
COPY backend/ ./
RUN npx prisma generate && npm run build

############### 3. Runtime ###############
FROM node:20-slim
RUN apt-get update && apt-get install -y --no-install-recommends openssl ca-certificates \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /app
ENV NODE_ENV=production

COPY --from=api-build /app/dist ./dist
COPY --from=api-build /app/node_modules ./node_modules
COPY --from=api-build /app/prisma ./prisma
COPY --from=api-build /app/package.json ./
COPY --from=flutter   /flutter/build/web ./web

COPY backend/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 3000
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["node", "dist/main.js"]
