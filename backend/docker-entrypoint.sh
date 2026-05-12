#!/bin/sh
set -e

echo "[entrypoint] waiting for database..."
node -e "
const {PrismaClient} = require('@prisma/client');
const c = new PrismaClient();
const wait = async () => {
  for (let i = 0; i < 30; i++) {
    try { await c.\$queryRaw\`SELECT 1\`; return; }
    catch { await new Promise(r => setTimeout(r, 1000)); }
  }
  throw new Error('database not reachable after 30s');
};
wait().then(() => c.\$disconnect()).catch(e => { console.error(e.message); process.exit(1); });
"

echo "[entrypoint] applying migrations..."
npx --no-install prisma migrate deploy

COUNT=$(node -e "
const {PrismaClient} = require('@prisma/client');
const c = new PrismaClient();
c.company.count().then(n => { process.stdout.write(String(n)); return c.\$disconnect(); }).catch(() => { process.stdout.write('-1'); });
")

if [ "$COUNT" = "0" ]; then
  echo "[entrypoint] seeding fresh database..."
  npx --no-install prisma db seed
else
  echo "[entrypoint] database already has $COUNT companies, skipping seed"
fi

echo "[entrypoint] starting API on port ${PORT:-3000}..."
exec "$@"
