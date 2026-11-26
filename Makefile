COMPOSE ?= docker compose

.PHONY: help up down \
	up-prometheus down-prometheus \
	up-node-exporter down-node-exporter \
	up-cadvisor down-cadvisor \
	up-grafana down-grafana \
	up-alertmanager down-alertmanager \
	up-alertreceiver down-alertreceiver \
	up-loki down-loki \
	up-promtail down-promtail \
	up-tempo down-tempo

help:
	@echo "Start or stop the full stack:"
	@echo "  make up"
	@echo "  make down"
	@echo
	@echo "Start or stop one service (dependencies start with up):"
	@echo "  make up-prometheus      make down-prometheus"
	@echo "  make up-node-exporter   make down-node-exporter"
	@echo "  make up-cadvisor        make down-cadvisor"
	@echo "  make up-grafana         make down-grafana"
	@echo "  make up-alertmanager    make down-alertmanager"
	@echo "  make up-alertreceiver   make down-alertreceiver"
	@echo "  make up-loki            make down-loki"
	@echo "  make up-promtail        make down-promtail"
	@echo "  make up-tempo           make down-tempo"

up:
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

up-prometheus:
	$(COMPOSE) up -d prometheus

down-prometheus:
	$(COMPOSE) down prometheus

up-node-exporter:
	$(COMPOSE) up -d node-exporter

down-node-exporter:
	$(COMPOSE) down node-exporter

up-cadvisor:
	$(COMPOSE) up -d cadvisor

down-cadvisor:
	$(COMPOSE) down cadvisor

up-grafana:
	$(COMPOSE) up -d grafana

down-grafana:
	$(COMPOSE) down grafana

up-alertmanager:
	$(COMPOSE) up -d alertmanager

down-alertmanager:
	$(COMPOSE) down alertmanager

up-alertreceiver:
	$(COMPOSE) up -d alertreceiver

down-alertreceiver:
	$(COMPOSE) down alertreceiver

up-loki:
	$(COMPOSE) up -d loki

down-loki:
	$(COMPOSE) down loki

up-promtail:
	$(COMPOSE) up -d promtail

down-promtail:
	$(COMPOSE) down promtail

up-tempo:
	$(COMPOSE) up -d tempo

down-tempo:
	$(COMPOSE) down tempo
