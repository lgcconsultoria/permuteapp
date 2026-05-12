# PermuteApp

Plataforma de permuta multilateral: empresas trocam produtos/serviços usando
créditos virtuais (1 crédito = R$ 1,00) em vez de dinheiro.

## Rodar tudo com 1 comando (Docker)

Pré-requisito: Docker Desktop instalado e rodando.

```bash
docker compose up --build
```

Na primeira execução, o Docker:
1. Builda a imagem (multi-stage: Flutter web + NestJS),
2. Sobe um Postgres 16,
3. Aplica migrations e popula 3 empresas de teste (seed),
4. Sobe a API + app web na porta **3000**.

Abra no navegador: **http://localhost:3000** (app) e **http://localhost:3000/docs** (Swagger).

### Credenciais de teste

| Empresa             | Email   | Senha       | Saldo inicial |
| ------------------- | ------- | ----------- | ------------- |
| Hotel Aurora        | a@a.com | senha-1234  | UP$ 1.000     |
| BetaLog Transportes | b@b.com | senha-1234  | UP$ 500       |
| Gamma Marketing     | c@c.com | senha-1234  | UP$ 2.000     |

CNPJs (para a tela "Transferir"): `11.111.111/0001-11`, `22.222.222/0001-22`,
`33.333.333/0001-33`.

### Parar / resetar

```bash
docker compose down              # para os containers, preserva os dados
docker compose down -v           # apaga o volume do Postgres (re-roda o seed)
```

## Estrutura

```
permuteapp/
├── backend/      # API REST (NestJS + Prisma + PostgreSQL)
├── mobile/       # App Flutter (web + android + linux)
├── docs/         # Pesquisa, requisitos
├── Dockerfile    # Multi-stage: Flutter SDK + Node 20
└── docker-compose.yml
```

## Stack

| Camada    | Tecnologia                                          |
| --------- | --------------------------------------------------- |
| Mobile    | Flutter (Dart) — Riverpod + go_router + Dio         |
| Backend   | NestJS (TypeScript) + Prisma ORM                    |
| Banco     | PostgreSQL 16                                       |
| API       | REST + OpenAPI/Swagger                              |
| Auth      | JWT (access + refresh com rotação)                  |

## Escopo do MVP

- Cadastro de empresa e autenticação (JWT).
- Carteira de créditos com saldo e extrato (double-entry bookkeeping).
- Marketplace de ofertas (CRUD).
- Transferência P2P de créditos entre empresas (atômica, SERIALIZABLE).

Próximas fases sugeridas: e-vouchers, cobranças, e-commerce integrado,
analytics, integração ERP.

## Desenvolvimento sem Docker

Ver [`backend/README.md`](backend/README.md) e [`mobile/README.md`](mobile/README.md).

## Documentação

- [Pesquisa de mercado e requisitos](docs/pesquisa-plataformas-permuta.md)
