COMPOSE ?= docker compose

SERVICES := prometheus node-exporter cadvisor grafana alertmanager alertreceiver loki promtail tempo

.PHONY: help up

help:
	@echo "Start the full stack:"
	@echo "  make up"
	@echo
	@echo "Start one service (dependencies start with it):"
	@$(foreach service,$(SERVICES),echo "  make up-$(service)";)

up:
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

define service_target
.PHONY: up-$(1)
up-$(1):
	$(COMPOSE) up -d $(1)

endef

$(foreach service,$(SERVICES),$(eval $(call service_target,$(service))))
