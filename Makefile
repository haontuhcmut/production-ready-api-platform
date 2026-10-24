
.PHONY: help install dev run start prod lint format check clean
.PHONY: docker-dev docker-prod docker-logs docker-stop docker-clean

.DEFAULT_GOAL := help

# Configuration
HOST ?= 0.0.0.0
PORT ?= 8000
WORKERS ?= 2
LOG_LEVEL ?= info

# Docker Compose files
COMPOSE_DEV := docker-compose-dev.yml
COMPOSE_PROD := docker-compose-prod.yml

help: ## Show available commands
	@grep -E '^[a-zA-Z_-]+:.*## ' $(MAKEFILE_LIST) | \
	awk 'BEGIN {FS = ":.*## "} {printf "%-16s %s\n", $$1, $$2}'

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

docker-dev: ## Build and start development container
	docker compose -f $(COMPOSE_DEV) up --build -d

docker-prod: ## Build and start production container
	docker compose -f $(COMPOSE_PROD) up --build -d

docker-logs: ## Follow development container logs
	docker compose -f $(COMPOSE_DEV) logs -f api

docker-stop: ## Stop development container
	docker compose -f $(COMPOSE_DEV) down

docker-clean: ## Stop development container and remove its volumes
	docker compose -f $(COMPOSE_DEV) down --volumes
