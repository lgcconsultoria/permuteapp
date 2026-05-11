# PermuteApp API

API REST do PermuteApp em NestJS + Prisma + PostgreSQL.

## Módulos (MVP)

- `auth/` — registro, login, refresh, logout (JWT access + refresh).
- `companies/` — perfil da empresa, busca por CNPJ.
- `offers/` — CRUD de ofertas, marketplace público (autenticado).
- `wallet/` — saldo e extrato com double-entry bookkeeping.
- `transactions/` — transferência P2P de créditos (atômica, SERIALIZABLE).

## Setup

```bash
cp .env.example .env
npm install
npx prisma migrate dev --name init
npm run start:dev
```

Swagger: `http://localhost:3000/docs`

## Modelo de dados

Cada `Transaction` é gerada com exatamente duas `LedgerEntry` (DEBIT + CREDIT)
de mesmo valor. As atualizações de saldo e a criação dos lançamentos ocorrem
no mesmo `prisma.$transaction` com isolamento `SERIALIZABLE`, garantindo que
transferências concorrentes não consigam sacar mais do que o saldo disponível.

Valores são armazenados em **centavos** (`BigInt`) — 1 crédito = R$ 1,00 = 100 centavos.
