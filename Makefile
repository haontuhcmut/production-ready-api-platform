
.PHONY: help install dev run start prod lint format check clean
.PHONY: docker-dev docker-prod docker-logs docker-stop docker-clean
.PHONY: gateway-up gateway-down gateway-logs gateway-status gateway-config
.PHONY: logging-up logging-down logging-logs logging-status logging-config
.PHONY: monitoring-up monitoring-down monitoring-logs monitoring-status monitoring-config
.PHONY: observability-network

.DEFAULT_GOAL := help

# Configuration
HOST ?= 0.0.0.0
PORT ?= 8000
WORKERS ?= 2
LOG_LEVEL ?= info

# Docker Compose files
COMPOSE_DEV := docker-compose-dev.yml
COMPOSE_PROD := docker-compose-prod.yml
COMPOSE_LOGGING := logging-stack/docker-compose.yaml
COMPOSE_MONITORING := monitoring-stack/docker-compose.yaml

help: ## Show available commands
	@grep -E '^[a-zA-Z_-]+:.*## ' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*## "} {printf "%-22s %s\n", $$1, $$2}'

install: ## Install project dependencies
	uv sync

dev: ## Run FastAPI locally in development mode
	ENV=dev HOST=$(HOST) PORT=$(PORT) LOG_LEVEL=$(LOG_LEVEL) ./entrypoint.sh

run: dev ## Alias for dev

start: ## Start FastAPI locally using default configuration
	./entrypoint.sh

prod: ## Run FastAPI locally in production mode
	ENV=prod HOST=$(HOST) PORT=$(PORT) WORKERS=$(WORKERS) LOG_LEVEL=$(LOG_LEVEL) ./entrypoint.sh

lint: ## Run Ruff lint checks
	uv run ruff check .

format: ## Format Python files with Ruff
	uv run ruff format .

check: ## Check linting and formatting
	uv run ruff check .
	uv run ruff format --check .

clean: ## Remove Python cache files
	find . -type d -name __pycache__ -prune -exec rm -rf {} +
	find . -type f -name '*.pyc' -delete

# Shared Docker network
observability-network: ## Create shared observability network if needed
	docker network inspect observability-network >/dev/null 2>&1 || docker network create observability-network

# Gateway
gateway-up: observability-network ## Build and start Nginx, Kong, and FastAPI
	docker compose -f $(COMPOSE_DEV) up --build -d

gateway-down: ## Stop gateway and FastAPI stack
	docker compose -f $(COMPOSE_DEV) down

gateway-logs: ## Follow gateway and FastAPI logs
	docker compose -f $(COMPOSE_DEV) logs -f nginx kong api

gateway-status: ## Show gateway stack status
	docker compose -f $(COMPOSE_DEV) ps

gateway-config: ## Validate gateway Compose configuration
	docker compose -f $(COMPOSE_DEV) config

# Backward-compatible Docker commands
docker-dev: gateway-up ## Alias for gateway-up

docker-prod: ## Build and start production container
	docker compose -f $(COMPOSE_PROD) up --build -d

docker-logs: ## Follow development Compose logs
	docker compose -f $(COMPOSE_DEV) logs -f

docker-stop: gateway-down ## Alias for gateway-down

docker-clean: ## Stop development stack and remove its volumes
	docker compose -f $(COMPOSE_DEV) down --volumes

# Logging
logging-up: observability-network ## Start Loki and Alloy
	docker compose -f $(COMPOSE_LOGGING) up -d

logging-down: ## Stop logging stack
	docker compose -f $(COMPOSE_LOGGING) down

logging-logs: ## Follow logging stack logs
	docker compose -f $(COMPOSE_LOGGING) logs -f

logging-status: ## Show logging stack status
	docker compose -f $(COMPOSE_LOGGING) ps

logging-config: ## Validate logging Compose configuration
	docker compose -f $(COMPOSE_LOGGING) config

# Monitoring
monitoring-up: observability-network ## Start Prometheus and Grafana
	docker compose --env-file monitoring-stack/.env -f $(COMPOSE_MONITORING) up -d

monitoring-down: ## Stop monitoring stack
	docker compose --env-file monitoring-stack/.env -f $(COMPOSE_MONITORING) down

monitoring-logs: ## Follow monitoring stack logs
	docker compose --env-file monitoring-stack/.env -f $(COMPOSE_MONITORING) logs -f

monitoring-status: ## Show monitoring stack status
	docker compose --env-file monitoring-stack/.env -f $(COMPOSE_MONITORING) ps

monitoring-config: observability-network ## Validate monitoring Compose configuration
	docker compose --env-file monitoring-stack/.env -f $(COMPOSE_MONITORING) config
