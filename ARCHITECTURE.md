# Obseye Architecture

## Overview

Obseye is a comprehensive monitoring stack that provides full observability through metrics collection, log aggregation, visualization, and alerting.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        Docker Network                            │
│                        (monitoring)                              │
│                                                                  │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐   │
│  │   Grafana    │────▶│  Prometheus  │────▶│ Alertmanager │   │
│  │   :3000      │     │   :9090      │     │    :9093     │   │
│  │              │     │              │     │              │   │
│  │  Dashboards  │     │   Metrics    │     │   Alerts     │   │
│  │  Datasources │     │   Storage    │     │   Routing    │   │
│  └──────┬───────┘     └──────┬───────┘     └──────────────┘   │
│         │                    │                                  │
│         │                    │ Scrapes                          │
│         │                    │                                  │
│         │             ┌──────┴───────┬──────────────┐          │
│         │             │              │              │          │
│         │      ┌──────▼─────┐ ┌─────▼────┐  ┌──────▼──────┐  │
│         │      │   Node      │ │ cAdvisor │  │ Prometheus  │  │
│         │      │  Exporter   │ │  :8080   │  │   :9090     │  │
│         │      │   :9100     │ │          │  │             │  │
│         │      │             │ │ Container│  │ Self-Monitor│  │
│         │      │   System    │ │ Metrics  │  │             │  │
│         │      │   Metrics   │ │          │  │             │  │
│         │      └─────────────┘ └──────────┘  └─────────────┘  │
│         │                                                       │
│         │      ┌──────────────┐                                │
│         └─────▶│     Loki     │                                │
│                │    :3100     │                                │
│                │              │                                │
│                │     Log      │                                │
│                │ Aggregation  │                                │
│                └──────▲───────┘                                │
│                       │                                         │
│                       │ Pushes Logs                            │
│                       │                                         │
│                ┌──────┴──────┐                                 │
│                │  Promtail   │                                 │
│                │   :9080     │                                 │
│                │             │                                 │
│                │ Log Shipper │                                 │
│                └─────────────┘                                 │
│                       │                                         │
│                       │ Reads                                   │
│                       │                                         │
│              ┌────────┴────────┐                               │
│              │                 │                               │
│         /var/log          /var/lib/docker/                    │
│      (System Logs)        containers                           │
│                         (Container Logs)                       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

                        ┌─────────────┐
                        │   Users     │
                        │  Operators  │
                        └─────────────┘
                              │
                    ┌─────────┼─────────┐
                    │         │         │
                 :3000     :9090     :9093
                Grafana  Prometheus  Alertmanager
```

## Component Responsibilities

### Metrics Pipeline

1. **Exporters** (Node Exporter, cAdvisor)
   - Collect metrics from various sources
   - Expose metrics in Prometheus format
   - Run continuously in the background

2. **Prometheus**
   - Scrapes metrics from exporters
   - Stores time-series data
   - Evaluates alert rules
   - Provides query interface (PromQL)

3. **Alertmanager**
   - Receives alerts from Prometheus
   - Groups and routes alerts
   - Manages alert lifecycle
   - Sends notifications to receivers

### Logs Pipeline

1. **Promtail**
   - Reads log files from disk
   - Parses and labels logs
   - Pushes logs to Loki
   - Handles Docker container logs

2. **Loki**
   - Stores log data efficiently
   - Indexes metadata, not content
   - Provides query interface (LogQL)
   - Integrates with Grafana

### Visualization Layer

1. **Grafana**
   - Provides unified UI
   - Queries Prometheus for metrics
   - Queries Loki for logs
   - Displays pre-built dashboards
   - Shows alerts from Alertmanager

## Data Flow

### Metrics Flow
```
System/Container → Exporter → Prometheus → Grafana
                              ↓
                        Alertmanager
```

### Logs Flow
```
Log Files → Promtail → Loki → Grafana
```

### Alert Flow
```
Prometheus → Alertmanager → Notification Channels
             ↓
          Grafana (display)
```

## Network Architecture

All components run on the `monitoring` bridge network, enabling:
- Service discovery via container names
- Isolated network segment
- Easy inter-service communication
- No exposure to host network by default

## Storage

### Persistent Volumes

- `prometheus-data`: Metrics time-series database
- `alertmanager-data`: Alert state and silences
- `grafana-data`: Dashboards, users, settings
- `loki-data`: Log chunks and indexes

### Data Retention

- **Prometheus**: 30 days (configurable)
- **Loki**: 168 hours / 7 days (configurable)
- **Alertmanager**: Until resolved
- **Grafana**: Permanent

## Scalability Considerations

### Current Setup
- Single-node deployment
- Suitable for development and small deployments
- All components run on one host

### Scaling Options
- Prometheus: Federation, sharding
- Loki: Microservices mode, replication
- Grafana: Multiple instances with shared database
- Alertmanager: Clustering for high availability

## Security Model

### Current Implementation
- No authentication between internal services
- Default Grafana credentials (admin/admin)
- Services not exposed to internet
- All communication within Docker network

### Production Recommendations
- Enable authentication for all services
- Use TLS for external access
- Implement network policies
- Rotate default credentials
- Use secrets management
- Enable RBAC in Grafana

## Monitoring the Monitoring Stack

The stack monitors itself:
- Prometheus scrapes its own metrics
- Alertmanager is monitored by Prometheus
- Grafana exposes metrics for Prometheus
- Container metrics include monitoring containers
- Alert if monitoring components are down
