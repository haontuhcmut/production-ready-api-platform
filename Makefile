.PHONY: help install dev prod check clean
.PHONY: observability-network stack-up
.PHONY: gateway-up gateway-down gateway-logs gateway-status gateway-config
.PHONY: logging-up logging-down logging-logs logging-status logging-config
.PHONY: monitoring-up monitoring-down monitoring-logs monitoring-status monitoring-config

.DEFAULT_GOAL := help

# Configuration
HOST ?= 0.0.0.0
PORT ?= 8000
WORKERS ?= 2
LOG_LEVEL ?= info

# Docker Compose files
COMPOSE_DEV := docker-compose-dev.yml
COMPOSE_LOGGING := logging-stack/docker-compose.yaml
COMPOSE_MONITORING := monitoring-stack/docker-compose.yaml

help: ## Show available commands
	@echo "Available commands:"
	@echo "  make install             Install dependencies"
	@echo "  make dev                 Run FastAPI in development mode"
	@echo "  make prod                Run FastAPI in production mode"
	@echo "  make check               Run lint and format checks"
	@echo "  make clean               Remove Python cache files"
	@echo "  make stack-up            Start all services"
	@echo "  make gateway-up          Start API gateway"
	@echo "  make gateway-down        Stop API gateway"
	@echo "  make gateway-logs        Follow API gateway logs"
	@echo "  make gateway-status      Show API gateway status"
	@echo "  make gateway-config      Validate gateway configuration"
	@echo "  make logging-up          Start logging stack"
	@echo "  make logging-down        Stop logging stack"
	@echo "  make logging-logs        Follow logging logs"
	@echo "  make logging-status      Show logging status"
	@echo "  make logging-config      Validate logging configuration"
	@echo "  make monitoring-up       Start monitoring stack"
	@echo "  make monitoring-down     Stop monitoring stack"
	@echo "  make monitoring-logs     Follow monitoring logs"
	@echo "  make monitoring-status   Show monitoring status"
	@echo "  make monitoring-config   Validate monitoring configuration"

install: ## Install project dependencies
	uv sync

dev: ## Run FastAPI locally in development mode
	ENV=dev HOST=$(HOST) PORT=$(PORT) LOG_LEVEL=$(LOG_LEVEL) ./entrypoint.sh

prod: ## Run FastAPI locally in production mode
	ENV=prod HOST=$(HOST) PORT=$(PORT) WORKERS=$(WORKERS) LOG_LEVEL=$(LOG_LEVEL) ./entrypoint.sh

check: ## Check linting and formatting
	uv run ruff check .
	uv run ruff format --check .

clean: ## Remove Python cache files
	find . -type d -name __pycache__ -prune -exec rm -rf {} +
	find . -type f -name '*.pyc' -delete

# Shared Docker network
observability-network: ## Create shared observability network if needed
	docker network inspect observability-network >/dev/null 2>&1 || docker network create observability-network

# Start all services
stack-up: gateway-up logging-up monitoring-up ## Start gateway, logging, and monitoring

# Gateway
gateway-up: observability-network ## Build and start API gateway
	docker compose -f $(COMPOSE_DEV) up --build -d

gateway-down: ## Stop API gateway
	docker compose -f $(COMPOSE_DEV) down

gateway-logs: ## Follow API gateway logs
	docker compose -f $(COMPOSE_DEV) logs -f nginx kong api

gateway-status: ## Show API gateway status
	docker compose -f $(COMPOSE_DEV) ps

gateway-config: ## Validate gateway Compose configuration
	docker compose -f $(COMPOSE_DEV) config --quiet

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
	docker compose -f $(COMPOSE_LOGGING) config --quiet

# Monitoring
monitoring-up: observability-network ## Start Prometheus and Grafana
	docker compose --env-file monitoring-stack/.env -f $(COMPOSE_MONITORING) up -d

monitoring-down: ## Stop monitoring stack
	docker compose --env-file monitoring-stack/.env -f $(COMPOSE_MONITORING) down

monitoring-logs: ## Follow monitoring stack logs
	docker compose --env-file monitoring-stack/.env -f $(COMPOSE_MONITORING) logs -f

monitoring-status: ## Show monitoring stack status
	docker compose --env-file monitoring-stack/.env -f $(COMPOSE_MONITORING) ps

monitoring-config: ## Validate monitoring Compose configuration
	docker compose --env-file monitoring-stack/.env -f $(COMPOSE_MONITORING) config --quiet