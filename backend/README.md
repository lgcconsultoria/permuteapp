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
npx prisma db seed       # popula 3 empresas + 5 ofertas + saldos
npm run start:dev
```

Swagger: `http://localhost:3000/docs`

### Credenciais de teste (após `prisma db seed`)

| Empresa            | Email   | Senha       | Saldo       |
| ------------------ | ------- | ----------- | ----------- |
| Hotel Aurora       | a@a.com | senha-1234  | UP$ 1.000   |
| BetaLog Transportes| b@b.com | senha-1234  | UP$ 500     |
| Gamma Marketing    | c@c.com | senha-1234  | UP$ 2.000   |

O seed é idempotente: rodar de novo reseta apenas os saldos e não duplica
ofertas/empresas.

## Modelo de dados

Cada `Transaction` é gerada com exatamente duas `LedgerEntry` (DEBIT + CREDIT)
de mesmo valor. As atualizações de saldo e a criação dos lançamentos ocorrem
no mesmo `prisma.$transaction` com isolamento `SERIALIZABLE`, garantindo que
transferências concorrentes não consigam sacar mais do que o saldo disponível.

Valores são armazenados em **centavos** (`BigInt`) — 1 crédito = R$ 1,00 = 100 centavos.
