.PHONY: help install dev prod check clean
.PHONY: observability-network stack-up
.PHONY: gateway-up gateway-down gateway-logs gateway-status gateway-config
.PHONY: logging-up logging-down logging-logs logging-status logging-config
.PHONY: monitoring-up monitoring-down monitoring-logs monitoring-status monitoring-config
.PHONY: monitoring-alerts-check monitoring-alertmanager-logs monitoring-alertmanager-status
.PHONY: dashboard-reload dashboard-validate

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

# Monitoring configuration
PROMETHEUS_CONFIG := monitoring-stack/prometheus/prometheus.yml
PROMETHEUS_ALERTS := monitoring-stack/prometheus/alerts
ALERTMANAGER_CONFIG := monitoring-stack/alertmanager/alertmanager.yml
GRAFANA_DASHBOARDS := monitoring-stack/grafana/dashboards
MONITORING_ENV := --env-file monitoring-stack/.env

help: ## Show available commands
	@echo "Available commands:"
	@echo "  make install                       Install dependencies"
	@echo "  make dev                           Run FastAPI in development mode"
	@echo "  make prod                          Run FastAPI in production mode"
	@echo "  make check                         Run lint and format checks"
	@echo "  make clean                         Remove Python cache files"
	@echo ""
	@echo "Stack:"
	@echo "  make stack-up                      Start gateway, logging, and monitoring"
	@echo "  make observability-network         Create shared Docker network"
	@echo ""
	@echo "API Gateway:"
	@echo "  make gateway-up                    Build and start API gateway"
	@echo "  make gateway-down                  Stop API gateway"
	@echo "  make gateway-logs                  Follow API gateway logs"
	@echo "  make gateway-status                Show API gateway status"
	@echo "  make gateway-config                Validate gateway Compose configuration"
	@echo ""
	@echo "Logging:"
	@echo "  make logging-up                    Start Loki and Alloy"
	@echo "  make logging-down                  Stop logging stack"
	@echo "  make logging-logs                  Follow logging stack logs"
	@echo "  make logging-status                Show logging status"
	@echo "  make logging-config                Validate logging Compose configuration"
	@echo ""
	@echo "Monitoring and Alerting:"
	@echo "  make monitoring-up                 Start Prometheus, Grafana, Alertmanager"
	@echo "  make monitoring-down               Stop monitoring stack"
	@echo "  make monitoring-logs               Follow monitoring stack logs"
	@echo "  make monitoring-status             Show monitoring status"
	@echo "  make monitoring-config             Validate monitoring Compose configuration"
	@echo "  make monitoring-alerts-check       Validate Prometheus config and alert rules"
	@echo "  make monitoring-alertmanager-logs  Follow Alertmanager logs"
	@echo "  make monitoring-alertmanager-status Show Alertmanager status"
	@echo ""
	@echo "Grafana Dashboards:"
	@echo "  make dashboard-validate            Validate all dashboard JSON files"
	@echo "  make dashboard-reload              Validate dashboards and restart Grafana"

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
monitoring-up: observability-network monitoring-config ## Start Prometheus, Grafana, and Alertmanager
	docker compose $(MONITORING_ENV) -f $(COMPOSE_MONITORING) up -d

monitoring-down: ## Stop monitoring stack
	docker compose $(MONITORING_ENV) -f $(COMPOSE_MONITORING) down

monitoring-logs: ## Follow monitoring stack logs
	docker compose $(MONITORING_ENV) -f $(COMPOSE_MONITORING) logs -f

monitoring-status: ## Show monitoring stack status
	docker compose $(MONITORING_ENV) -f $(COMPOSE_MONITORING) ps

monitoring-config: ## Validate monitoring Compose configuration
	docker compose $(MONITORING_ENV) -f $(COMPOSE_MONITORING) config --quiet

monitoring-alerts-check: ## Validate Prometheus configuration and alert rules
	docker run --rm
		--entrypoint /bin/promtool
		-v "$(CURDIR)/$(PROMETHEUS_CONFIG):/etc/prometheus/prometheus.yml:ro"
		-v "$(CURDIR)/$(PROMETHEUS_ALERTS):/etc/prometheus/alerts:ro"
		prom/prometheus:latest
		check config /etc/prometheus/prometheus.yml
	docker run --rm
		--entrypoint /bin/promtool
		-v "$(CURDIR)/$(PROMETHEUS_ALERTS):/etc/prometheus/alerts:ro"
		prom/prometheus:latest
		check rules /etc/prometheus/alerts/api-alerts.yml

monitoring-alertmanager-logs: ## Follow Alertmanager logs
	docker compose $(MONITORING_ENV) -f $(COMPOSE_MONITORING) logs -f --tail=100 alertmanager

monitoring-alertmanager-status: ## Show Alertmanager status
	docker compose $(MONITORING_ENV) -f $(COMPOSE_MONITORING) ps alertmanager

# Grafana dashboards
dashboard-validate: ## Validate all provisioned dashboard JSON files
	@files="$$(find $(GRAFANA_DASHBOARDS) -type f -name '*.json' -print)"; \
	if [ -z "$$files" ]; then \
		echo "ERROR: No dashboard JSON files found"; \
		exit 1; \
	fi; \
	for file in $$files; do \
		python3 -m json.tool "$$file" > /dev/null || exit 1; \
	done
	@echo "All Grafana dashboard JSON files are valid."

dashboard-reload: dashboard-validate ## Validate dashboards and restart Grafana
	docker restart monitoring-grafana
	@echo "Grafana restarted. Refresh your dashboards."
