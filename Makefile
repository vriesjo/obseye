.PHONY: help start stop restart logs ps clean status

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

start: ## Start all monitoring services
	docker compose up -d
	@echo "Monitoring stack started!"
	@echo "Grafana:       http://localhost:3000 (admin/admin)"
	@echo "Prometheus:    http://localhost:9090"
	@echo "Alertmanager:  http://localhost:9093"

stop: ## Stop all monitoring services
	docker compose down

restart: ## Restart all monitoring services
	docker compose restart

logs: ## Show logs from all services
	docker compose logs -f

ps: ## Show status of all services
	docker compose ps

status: ## Show detailed status of all services
	@echo "=== Service Status ==="
	@docker compose ps
	@echo ""
	@echo "=== Prometheus Targets ==="
	@curl -s http://localhost:9090/api/v1/targets 2>/dev/null | grep -o '"health":"[^"]*"' | sort | uniq -c || echo "Prometheus not accessible"

clean: ## Stop services and remove all data
	docker compose down -v
	@echo "All data removed!"
