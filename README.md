# Obseye - Complete Monitoring Stack

A comprehensive observability stack providing metrics collection, log aggregation, dashboards, and alerting capabilities.

## Features

- **Metrics Collection**: Prometheus for time-series metrics
- **Log Aggregation**: Loki for centralized logging
- **Visualization**: Grafana dashboards for metrics and logs
- **Alerting**: Alertmanager for alert routing and management
- **System Metrics**: Node Exporter for host-level metrics
- **Container Metrics**: cAdvisor for Docker container metrics
- **Log Shipping**: Promtail for log collection and forwarding

## Components

| Component | Port | Description |
|-----------|------|-------------|
| Grafana | 3000 | Visualization and dashboards |
| Prometheus | 9090 | Metrics collection and storage |
| Alertmanager | 9093 | Alert management |
| Loki | 3100 | Log aggregation backend |
| Node Exporter | 9100 | System metrics exporter |
| cAdvisor | 8080 | Container metrics |

## Quick Start

### Prerequisites

- Docker Engine 20.10+
- Docker Compose v2+ (included with Docker Desktop)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/vriesjo/obseye.git
cd obseye
```

2. (Optional) Configure environment variables:
```bash
# Copy the example environment file
cp .env.example .env

# Edit .env to customize settings (e.g., Grafana password)
nano .env
```

3. Start the monitoring stack:
```bash
docker compose up -d
```

4. Verify all services are running:
```bash
docker compose ps
```

### Accessing Services

- **Grafana**: http://localhost:3000
  - Default credentials: `admin` / `admin`
  - Pre-configured dashboards:
    - System Metrics: CPU, Memory, Disk, Network
    - Container Metrics: Docker container statistics
    - Logs: Centralized log viewing

- **Prometheus**: http://localhost:9090
  - Query metrics and view targets

- **Alertmanager**: http://localhost:9093
  - View and manage alerts

## Configuration

### Prometheus

Configuration files are located in `config/prometheus/`:
- `prometheus.yml`: Main Prometheus configuration
- `alerts.yml`: Alert rules definitions

### Alertmanager

Configuration located in `config/alertmanager/alertmanager.yml`:
- Configure receivers (email, Slack, PagerDuty, etc.)
- Set up routing rules
- Define inhibition rules

### Grafana

Configuration in `config/grafana/`:
- `provisioning/datasources/`: Auto-configured data sources
- `provisioning/dashboards/`: Dashboard provisioning
- `dashboards/`: Pre-built dashboard definitions

### Loki

Configuration in `config/loki/loki-config.yml`:
- Log retention settings
- Storage configuration
- Query limits

### Promtail

Configuration in `config/promtail/promtail-config.yml`:
- Log collection paths
- Label extraction rules
- Pipeline stages

## Alert Rules

Pre-configured alerts include:

### Instance Alerts
- **InstanceDown**: Service unavailable for 5+ minutes
- **HighCpuUsage**: CPU usage above 80% for 5+ minutes
- **HighMemoryUsage**: Memory usage above 85% for 5+ minutes
- **LowDiskSpace**: Disk usage above 80% for 5+ minutes

### Container Alerts
- **HighContainerMemory**: Container memory usage above 90%
- **ContainerRestarted**: Container restarting frequently

## Monitoring Targets

The stack monitors:

1. **System Resources**
   - CPU usage per core
   - Memory utilization
   - Disk I/O and space
   - Network traffic

2. **Containers**
   - Resource usage (CPU, memory)
   - Network statistics
   - Container health and restarts

3. **Services**
   - All monitoring stack components
   - Custom application metrics (add to Prometheus scrape config)

## Customization

### Adding Custom Metrics

Edit `config/prometheus/prometheus.yml` and add a new scrape job:

```yaml
scrape_configs:
  - job_name: 'my-app'
    static_configs:
      - targets: ['my-app:8080']
```

### Adding Custom Alerts

Edit `config/prometheus/alerts.yml` and add new alert rules:

```yaml
- alert: MyCustomAlert
  expr: my_metric > threshold
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "Alert description"
```

### Creating Custom Dashboards

1. Access Grafana at http://localhost:3000
2. Create or import dashboards
3. Export the JSON and save to `config/grafana/dashboards/`

## Data Persistence

Data is persisted in Docker volumes:
- `prometheus-data`: Prometheus time-series data
- `alertmanager-data`: Alertmanager state
- `grafana-data`: Grafana dashboards and settings
- `loki-data`: Loki log data

## Maintenance

### Viewing Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f prometheus
```

### Restarting Services

```bash
# Restart all
docker compose restart

# Restart specific service
docker compose restart prometheus
```

### Stopping the Stack

```bash
docker compose down
```

### Removing Data

```bash
# Stop and remove containers, networks, and volumes
docker compose down -v
```

## Troubleshooting

### Services Not Starting

Check logs for the failing service:
```bash
docker compose logs <service-name>
```

### No Metrics Appearing

1. Check Prometheus targets: http://localhost:9090/targets
2. Verify all targets are "UP"
3. Check service logs for errors

### Grafana Dashboard Not Loading

1. Verify datasources are configured: Configuration → Data Sources
2. Check Prometheus is accessible from Grafana container
3. Review Grafana logs: `docker compose logs grafana`

## Security Considerations

⚠️ **Important**: This stack is configured for development/testing:

- Change default Grafana password immediately in production
- Configure proper authentication for all services
- Use TLS/SSL for external access
- Restrict network access using firewalls
- Configure Alertmanager receivers with proper credentials
- Review and adjust retention policies

## License

MIT License

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
