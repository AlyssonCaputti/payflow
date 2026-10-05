# PayFlow — Pipeline de Dados de Pagamentos com Garantias de Consistência

> Projeto de portfólio de Engenharia de Dados. Foco: **provar** garantias (ACID, idempotência,
> at-least-once → efeito exactly-once, reconciliação), não só mover dados.

## A ideia em 30 segundos

Um fluxo de pagamentos (estilo PIX) onde:

1. Um banco **OLTP ACID** (Postgres) registra transferências com **ledger de partidas dobradas**.
2. Eventos saem via **Outbox Pattern** para um broker (Redpanda/Kafka) — modelo **BASE / eventual**.
3. Um consumidor **idempotente** grava no **Lakehouse** (Delta Lake em MinIO) — camada **Bronze**.
4. **dbt + DuckDB** constroem **Silver** (dedup, SCD2, late data) e **Gold** (métricas).
5. **Dagster** orquestra, **testes de caos** provam que duplicar/derrubar/reprocessar não corrompe nada.
6. Uma **reconciliação** compara OLTP × Gold e prova: `soma(origem) == soma(destino)`.

## Arquitetura

```
 Gerador ──► Postgres (ACID, CP) ──► tabela outbox ──► Relay ──► Redpanda (at-least-once)
 (Python)    ledger + idempotency        (mesma tx)                        │
                                                                           ▼
                                          Consumer idempotente ──► Bronze (Delta/MinIO)
                                          (DLQ p/ mensagens ruins)         │
                                                                           ▼
                                                  dbt+DuckDB: Silver ──► Gold ──► Reconciliação
                                                                           ▲
                                                          Dagster (orquestra, backfill, checks)
```

## Stack (todas atuais e pedidas em vagas)

| Camada | Ferramenta | Por quê |
|---|---|---|
| OLTP | PostgreSQL 16 | ACID, constraints, transações |
| Streaming | Redpanda (API Kafka) | Kafka sem Zookeeper, sobe em 1 container |
| Lake | MinIO + Delta Lake (`deltalake` py) | S3 local + ACID no lake + MERGE |
| Transformação | dbt-core + dbt-duckdb | SQL versionado, testes, lineage |
| Orquestração | Dagster | Assets, partições, backfill |
| Qualidade | dbt tests + contratos (pydantic) | Data contracts + DLQ |
| Infra | Docker Compose, Makefile | 1 comando para subir |
| CI | GitHub Actions | lint + testes |
| Linguagem | Python 3.11+, SQL | |

## Estrutura

```
payflow/
├─ docs/            conceitos, passo a passo, checklist do currículo
├─ infra/           docker-compose.yml
├─ sql/             DDL do Postgres (você escreve)
├─ src/             producer, outbox_relay, consumer, common
├─ dbt_project/     models silver/gold
├─ orchestration/   Dagster
├─ data_contracts/  schemas dos eventos
└─ tests/           unit + chaos
```

## Leia nesta ordem

1. [docs/00-conceitos.md](docs/00-conceitos.md) — a teoria que você vai aplicar (20 min)
2. [docs/01-passo-a-passo.md](docs/01-passo-a-passo.md) — 10 fases com tempo, entregável e prova
3. [docs/02-curriculo-e-entrevista.md](docs/02-curriculo-e-entrevista.md) — como vender e defender

**Tempo estimado:** 14–18h (dois fins de semana). Existe um **MVP de ~8h** marcado no passo a passo.
