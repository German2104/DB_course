SHELL := /bin/zsh

include .env
export

DC := docker compose

.PHONY: up down logs logs-api psql reset run-queries api api-test

up:
	$(DC) up -d

down:
	$(DC) down

logs:
	$(DC) logs -f postgres

logs-api:
	$(DC) logs -f api

psql:
	$(DC) exec postgres psql -U $(POSTGRES_USER) -d $(POSTGRES_DB)

run-queries:
	$(DC) exec -T postgres psql -U $(POSTGRES_USER) -d $(POSTGRES_DB) -f /opt/db/queries/quick_checks.sql

reset:
	$(DC) down -v
	$(DC) up -d

api:
	$(DC) up -d api

api-test:
	cd backend && pytest -q
