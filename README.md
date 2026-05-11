# PermuteApp

Plataforma de permuta multilateral: empresas trocam produtos/serviços usando
créditos virtuais (1 crédito = R$ 1,00) em vez de dinheiro.

## Estrutura do repositório

```
permuteapp/
├── backend/      # API REST (NestJS + Prisma + PostgreSQL)
├── mobile/       # App móvel (Flutter)
├── docs/         # Pesquisa, requisitos, arquitetura
└── docker-compose.yml
```

## Stack

| Camada    | Tecnologia                                         |
| --------- | -------------------------------------------------- |
| Mobile    | Flutter (Dart)                                     |
| Backend   | NestJS (TypeScript) + Prisma ORM                   |
| Banco     | PostgreSQL                                         |
| API       | REST + OpenAPI/Swagger                             |
| Auth      | JWT (access + refresh)                             |

## Escopo do MVP

- Cadastro de empresa e autenticação (JWT).
- Carteira de créditos com saldo e extrato.
- Marketplace de ofertas (CRUD).
- Transferência P2P de créditos entre empresas (contabilidade dupla, atômica).

Próximas fases: e-vouchers, e-commerce, cobranças, analytics, integração ERP.

## Subindo o ambiente local

```bash
# 1. Banco
docker-compose up -d postgres

# 2. Backend
cd backend
cp .env.example .env
npm install
npx prisma migrate dev
npm run start:dev
# API em http://localhost:3000, docs em http://localhost:3000/docs

# 3. Mobile
cd mobile
flutter pub get
flutter run
```

## Documentação

- [Pesquisa de mercado e requisitos](docs/pesquisa-plataformas-permuta.md)
