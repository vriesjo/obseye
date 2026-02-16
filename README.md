# obseye

Complete monitoring stack for microservice observability. This stack provides comprehensive SRE metrics including latencies, errors, saturation, and alerting.

## Deployment Options

This monitoring stack can be deployed in two ways:
1. **Kubernetes (Recommended)** - Production-ready deployment with Helm or plain Kubernetes manifests
2. **Docker Compose (Legacy)** - Local development and testing

## Quick Start - Kubernetes

### Prerequisites

- **Kubernetes cluster**: Version 1.20 or higher
- **kubectl**: Configured to access your cluster
- **Helm**: Version 3.x (optional, for Helm deployment)
- **Storage**: StorageClass configured for PersistentVolumes

### Deploy with Kubernetes Manifests

Deploy the entire monitoring stack as a single Pod with 4 sidecar containers:

```bash
kubectl apply -f deployment.yaml
```

This creates:
- ConfigMap with all configuration files
- 4 PersistentVolumeClaims for data storage
- Deployment with 4 sidecar containers (Prometheus, Grafana, Loki, Alertmanager)
- Service exposing all monitoring endpoints

Wait about 60 seconds for all containers to initialize.

### Deploy with Helm

For production deployments with customizable values:

```bash
# Install the Helm chart
helm install obseye ./charts/obseye

# Or with custom values
helm install obseye ./charts/obseye -f custom-values.yaml
```

### Access the Services

Port-forward to access Grafana:

```bash
kubectl port-forward service/obseye 3000:3000
```

Then access Grafana at http://localhost:3000 (default credentials: admin/admin)

Port-forward other services as needed:

```bash
# Prometheus
kubectl port-forward service/obseye 9090:9090

# Loki
kubectl port-forward service/obseye 3100:3100

# Alertmanager
kubectl port-forward service/obseye 9093:9093
```

### Customizing the Deployment

Edit the Helm values file (`charts/obseye/values.yaml`) to customize:

- Container image versions
- Resource limits and requests
- Storage sizes
- Admin credentials
- Retention periods

Example custom values:

```yaml
prometheus:
  retention: 30d
  resources:
    limits:
      memory: 1Gi

grafana:
  adminPassword: "changeme"

persistence:
  enabled: true
  prometheus:
    size: 20Gi
```

Apply custom values:

```bash
helm upgrade obseye ./charts/obseye -f custom-values.yaml
```

## Quick Start - Docker Compose (Legacy)

> **Note**: Docker Compose deployment is deprecated. Please use Kubernetes for production deployments.

Get the entire monitoring stack running with a single command:

```bash
docker-compose up -d
```

Wait about 30 seconds for all services to initialize, then access Grafana at http://localhost:3000

### Prerequisites for Docker Compose

- **Docker**: Version 20.10 or higher
- **Docker Compose**: Version 1.29 or higher (v2 recommended)
- **System Resources**:
  - Minimum: 4 GB RAM, 2 CPU cores, 10 GB disk space
  - Recommended: 8 GB RAM, 4 CPU cores, 20 GB disk space

## Architecture

### Kubernetes Deployment Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                       Kubernetes Pod (obseye)                    │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │  Prometheus  │  │   Grafana    │  │     Loki     │         │
│  │   :9090      │  │    :3000     │  │    :3100     │         │
│  └──────────────┘  └──────────────┘  └──────────────┘         │
│                                                                  │
│  ┌──────────────┐                                               │
│  │ Alertmanager │                                               │
│  │    :9093     │                                               │
│  └──────────────┘                                               │
│                                                                  │
│  All containers share localhost networking                      │
│  Configurations mounted from ConfigMap                          │
│  Data persisted in PersistentVolumes                           │
└─────────────────────────────────────────────────────────────────┘
                            ▲
                            │
                   ┌────────┴────────┐
                   │  Service (ClusterIP)  │
                   │  Exposes all ports    │
                   └───────────────────────┘
```

### Docker Compose Architecture (Legacy)

```
┌─────────────────────────────────────────────────────────────────┐
│                          Grafana (Port 3000)                     │
│                    Dashboards & Visualization                    │
└───────────────┬──────────────────────────┬──────────────────────┘
                │                          │
                │                          │
        ┌───────▼────────┐        ┌────────▼─────────┐
        │   Prometheus   │        │       Loki       │
        │   (Port 9090)  │        │   (Port 3100)    │
        │ Metrics Store  │        │    Log Store     │
        └───────┬────────┘        └────────▲─────────┘
                │                          │
    ┌───────────┼──────────────┐          │
    │           │              │           │
┌───▼────┐ ┌───▼────┐  ┌──────▼───┐  ┌───┴────────┐
│  Node  │ │cAdvisor│  │Alertmgr  │  │  Promtail  │
│Exporter│ │  8080  │  │   9093   │  │            │
│  9100  │ └────────┘  └─────┬────┘  └────────────┘
└────────┘                   │
   Host                      │
  Metrics              ┌─────▼──────┐
                       │   Alert    │
                       │  Receiver  │
                       │    9094    │
                       └────────────┘
```

## Migrating from Docker Compose to Kubernetes

If you're currently using the Docker Compose deployment and want to migrate to Kubernetes:

### Step 1: Backup Your Data (Optional)

If you want to preserve Grafana dashboards or Prometheus data:

```bash
# Backup Grafana data
docker run --rm \
  -v obseye_grafana-data:/data \
  -v $(pwd)/backup:/backup \
  alpine tar czf /backup/grafana-backup-$(date +%Y%m%d).tar.gz -C /data .

# Backup Prometheus data
docker run --rm \
  -v obseye_prometheus-data:/data \
  -v $(pwd)/backup:/backup \
  alpine tar czf /backup/prometheus-backup-$(date +%Y%m%d).tar.gz -C /data .
```

### Step 2: Stop Docker Compose Stack

```bash
# Stop all containers
docker-compose down

# Optional: Remove volumes (if you don't need to preserve data)
docker-compose down -v
```

### Step 3: Deploy to Kubernetes

Choose one of the deployment methods:

**Option A: Using plain Kubernetes manifests**
```bash
kubectl apply -f deployment.yaml
```

**Option B: Using Helm**
```bash
helm install obseye ./charts/obseye
```

### Step 4: Restore Data (Optional)

If you backed up data in Step 1, you can restore it:

```bash
# Get the pod name
POD_NAME=$(kubectl get pods -l app=obseye -o jsonpath='{.items[0].metadata.name}')

# Restore Grafana data
kubectl cp backup/grafana-backup-YYYYMMDD.tar.gz $POD_NAME:/tmp/grafana-backup.tar.gz -c grafana
kubectl exec $POD_NAME -c grafana -- sh -c "cd /var/lib/grafana && tar xzf /tmp/grafana-backup.tar.gz"

# Restart the pod to apply changes
kubectl delete pod $POD_NAME
```

### Step 5: Verify Deployment

```bash
# Check pod status
kubectl get pods -l app=obseye

# Check all containers are running
kubectl describe pod -l app=obseye

# Port-forward and access Grafana
kubectl port-forward service/obseye 3000:3000
```

### Key Differences Between Docker Compose and Kubernetes

| Aspect | Docker Compose | Kubernetes |
|--------|----------------|------------|
| **Architecture** | Multiple containers in separate networks | All containers in one Pod, shared localhost |
| **Configuration** | Files copied into image at build time | ConfigMaps mounted at runtime |
| **Scaling** | Manual (docker-compose up --scale) | Automatic with HPA (if enabled) |
| **Networking** | Bridge network, service names | Localhost within Pod, Service for external access |
| **Storage** | Docker volumes | PersistentVolumes with PVCs |
| **Health Checks** | Docker healthcheck | Kubernetes liveness/readiness probes |
| **Updates** | Requires rebuild and restart | Rolling updates with zero downtime |
| **Image Building** | Dockerfile + docker-compose build | Not required (uses official images) |

### Configuration Changes

In Kubernetes deployment:
- All services communicate via `localhost` instead of service names
- Configurations are managed through ConfigMaps
- No supervisord - each service runs as a separate container
- No custom Dockerfile - uses official upstream images
- Data persistence through PersistentVolumes instead of Docker volumes

## Access Information (Docker Compose)

| Service | URL | Default Credentials | Purpose |
|---------|-----|-------------------|---------|
| **Grafana** | http://localhost:3000 | admin / admin | Dashboards and visualization |
| **Prometheus** | http://localhost:9090 | none | Metrics database and queries |
| **Alertmanager** | http://localhost:9093 | none | Alert management |
| **Alert Receiver** | http://localhost:9094 | none | Alert webhook receiver UI |
| **Node Exporter** | http://localhost:9100 | none | Host metrics exporter |
| **cAdvisor** | http://localhost:8080 | none | Container metrics |
| **Loki** | http://localhost:3100 | none | Log aggregation API |

> **Security Note**: Change the default Grafana password immediately in production:
> 1. Log in to Grafana with admin/admin
> 2. Navigate to Configuration → Users → admin
> 3. Click "Change Password"

## Services Overview

### 1. Grafana (Dashboarding)
- Pre-configured data sources for Prometheus and Loki
- Four default dashboards:
  - **Node Exporter Metrics**: CPU, memory, disk, network for the host system
  - **cAdvisor Container Metrics**: Resource usage for all containers
  - **Docker Overview**: High-level system overview with logs
  - **Proaktive-db Microservice SRE Metrics**: Latencies, errors, saturation for JVM microservices
- Persistent storage for dashboards and settings

### 2. Prometheus (Metrics Database)
- Scrapes metrics every 15 seconds
- 15-day retention period for metrics
- Monitors all stack components plus host and containers
- Alert rules for high CPU, memory, disk usage, and service health

### 3. Node Exporter (Host Metrics)
- Exposes system-level metrics from the host machine
- CPU, memory, disk I/O, network, filesystem statistics

### 4. cAdvisor (Container Metrics)
- Analyzes resource usage of all Docker containers
- Provides per-container CPU, memory, network, and disk metrics

### 5. Alertmanager (Alert Management)
- Receives alerts from Prometheus
- Routes alerts by severity (critical, warning)
- Sends notifications to Alert Receiver webhook

### 6. Alert Receiver (Alert UI)
- Simple webhook receiver for viewing alerts
- Displays all received alerts with full details
- Useful for testing alert configurations

### 7. Loki (Log Aggregation)
- Collects and stores logs from all Docker containers
- Indexed by container labels for efficient querying
- 31-day retention period for logs

### 8. Promtail (Log Collector)
- Scrapes logs from all running Docker containers
- Automatically discovers new containers
- Ships logs to Loki with container metadata

## Configuration

### Customizing Prometheus Scrape Interval

Edit `prometheus/prometheus.yml`:

```yaml
global:
  scrape_interval: 30s  # Change from 15s to 30s
```

### Customizing Data Retention

**Prometheus retention** (edit `docker-compose.yml`):
```yaml
prometheus:
  command:
    - '--storage.tsdb.retention.time=30d'  # Change from 15d to 30d
```

**Loki retention** (edit `loki/loki-config.yml`):
```yaml
limits_config:
  retention_period: 1440h  # 60 days in hours
```

### Adding Alert Notification Channels

Edit `alertmanager/alertmanager.yml` to add Slack, email, or other receivers:

**Slack Example**:
```yaml
receivers:
  - name: 'slack-notifications'
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/YOUR/WEBHOOK/URL'
        channel: '#alerts'
        title: 'Alert: {{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'
```

**Email Example**:
```yaml
receivers:
  - name: 'email-notifications'
    email_configs:
      - to: 'alerts@example.com'
        from: 'monitoring@example.com'
        smarthost: 'smtp.gmail.com:587'
        auth_username: 'your-email@gmail.com'
        auth_password: 'your-app-password'
```

Then update the route to use your new receiver:
```yaml
route:
  receiver: 'slack-notifications'  # or 'email-notifications'
```

## Using the Dashboards

### Node Exporter Metrics Dashboard
- **Location**: Grafana → Dashboards → Node Exporter Metrics
- **Shows**: Real-time host system metrics
- **Refresh**: Auto-refreshes every 5 seconds
- **Useful for**: Monitoring host health, identifying resource bottlenecks

### cAdvisor Container Metrics Dashboard
- **Location**: Grafana → Dashboards → cAdvisor Container Metrics  
- **Shows**: Per-container resource consumption
- **Useful for**: Finding resource-hungry containers, capacity planning

### Docker Overview Dashboard
- **Location**: Grafana → Dashboards → Docker Overview
- **Shows**: System-wide statistics, container logs
- **Useful for**: Quick health check, log analysis

### Proaktive-db Microservice SRE Metrics Dashboard
- **Location**: Grafana → Dashboards → Proaktive-db Microservice SRE Metrics
- **Shows**: HTTP request latencies (p50, p95, p99), error rates (5xx), saturation (CPU, JVM heap, threads)
- **Refresh**: Auto-refreshes every 5 seconds
- **Useful for**: Monitoring microservice performance, identifying bottlenecks, SRE golden signals

## Example Prometheus Queries

Run these queries in Prometheus (http://localhost:9090) or Grafana Explore:

**CPU usage per container**:
```promql
rate(container_cpu_usage_seconds_total{name!=""}[5m]) * 100
```

**Memory usage per container**:
```promql
container_memory_usage_bytes{name!=""}
```

**Available disk space**:
```promql
(node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100
```

**Network traffic rate**:
```promql
rate(node_network_receive_bytes_total[5m])
```

**Active alerts**:
```promql
ALERTS{alertstate="firing"}
```

## Alerting

### Configured Alert Rules

All alerts are defined in `prometheus/alerts.yml`:

| Alert | Condition | Duration | Severity |
|-------|-----------|----------|----------|
| HighCPUUsage | CPU > 80% | 5 minutes | warning |
| HighMemoryUsage | Memory > 90% | 5 minutes | warning |
| DiskSpaceLow | Disk < 10% free | 5 minutes | critical |
| ContainerDown | Container unavailable | 1 minute | critical |
| ServiceDown | Service unavailable | 2 minutes | critical |
| HighContainerMemory | Container memory > 90% | 5 minutes | warning |
| HighContainerCPU | Container CPU > 80% | 5 minutes | warning |

### Viewing Active Alerts

- **Prometheus**: http://localhost:9090/alerts
- **Alertmanager**: http://localhost:9093
- **Alert Receiver**: http://localhost:9094

### Testing Alerts

Generate a test alert by stressing your system:

```bash
# Install stress tool
sudo apt-get install stress

# Stress CPU for 5+ minutes to trigger HighCPUUsage alert
stress --cpu 8 --timeout 400s
```

## Viewing Logs

### Via Grafana (Recommended)
1. Go to http://localhost:3000
2. Navigate to Explore (compass icon in left sidebar)
3. Select "Loki" as the data source
4. Use log browser or enter a query:
   - `{container="prometheus"}` - Logs from Prometheus container
   - `{container=~".+"}` - Logs from all containers
   - `{container="grafana"} |= "error"` - Errors from Grafana

### Via Docker Compose
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f prometheus

# Last 100 lines
docker-compose logs --tail=100 grafana
```

## Commands

### Start the Stack
```bash
docker-compose up -d
```

### View Logs
```bash
docker-compose logs -f
```

### Check Status
```bash
docker-compose ps
```

### Stop the Stack
```bash
docker-compose down
```

### Stop and Remove All Data
```bash
docker-compose down -v
```

> **Warning**: The `-v` flag deletes all persistent data including metrics, logs, and dashboards.

### Restart a Single Service
```bash
docker-compose restart prometheus
```

### Update to Latest Images
```bash
docker-compose pull
docker-compose up -d
```

## Troubleshooting

### Services Won't Start

**Check Docker and Docker Compose versions**:
```bash
docker --version
docker-compose --version
```

**Check for port conflicts**:
```bash
sudo netstat -tulpn | grep -E '3000|8080|9090|9093|9094|9100|3100'
```

If ports are in use, either stop the conflicting service or change ports in `docker-compose.yml`.

### Grafana Shows "No Data"

1. **Verify Prometheus is running**:
   ```bash
   curl http://localhost:9090/-/healthy
   ```

2. **Check Prometheus targets**:
   Visit http://localhost:9090/targets - all should be "UP"

3. **Verify data source in Grafana**:
   Configuration → Data Sources → Prometheus → "Save & Test"

### cAdvisor Not Showing Container Metrics

**On Linux**: Ensure you have cgroup v1 or cAdvisor has proper permissions:
```bash
docker-compose logs cadvisor
```

**On Mac/Windows**: cAdvisor may have limited functionality. Use Docker Desktop's built-in metrics instead.

### High Memory Usage

The stack uses approximately 1-2 GB of RAM. To reduce memory:

1. **Reduce Prometheus retention**:
   ```yaml
   - '--storage.tsdb.retention.time=7d'
   ```

2. **Limit Loki retention**:
   ```yaml
   retention_period: 168h  # 7 days
   ```

3. **Stop unused services**:
   ```bash
   docker-compose stop cadvisor  # If not needed
   ```

### Logs Not Appearing in Loki

1. **Check Promtail logs**:
   ```bash
   docker-compose logs promtail
   ```

2. **Verify Docker socket permissions**:
   ```bash
   ls -l /var/run/docker.sock
   ```

3. **Test Loki connection**:
   ```bash
   curl http://localhost:3100/ready
   ```

## Backup and Restore

### Backup Grafana Dashboards
```bash
# Backup Grafana data
docker run --rm \
  -v obseye_grafana-data:/data \
  -v $(pwd)/backup:/backup \
  alpine tar czf /backup/grafana-backup-$(date +%Y%m%d).tar.gz -C /data .
```

### Backup Prometheus Data
```bash
# Backup Prometheus data
docker run --rm \
  -v obseye_prometheus-data:/data \
  -v $(pwd)/backup:/backup \
  alpine tar czf /backup/prometheus-backup-$(date +%Y%m%d).tar.gz -C /data .
```

### Restore from Backup
```bash
# Stop services
docker-compose down

# Restore Grafana
docker run --rm \
  -v obseye_grafana-data:/data \
  -v $(pwd)/backup:/backup \
  alpine sh -c "cd /data && tar xzf /backup/grafana-backup-YYYYMMDD.tar.gz"

# Restore Prometheus
docker run --rm \
  -v obseye_prometheus-data:/data \
  -v $(pwd)/backup:/backup \
  alpine sh -c "cd /data && tar xzf /backup/prometheus-backup-YYYYMMDD.tar.gz"

# Start services
docker-compose up -d
```

## Adding Custom Dashboards

### Method 1: Via Grafana UI
1. Log in to Grafana
2. Create your dashboard
3. Click "Save" (dashboard is automatically persisted)

### Method 2: Via Provisioning
1. Export your dashboard as JSON from Grafana
2. Save to `grafana/provisioning/dashboards/dashboards/my-dashboard.json`
3. Restart Grafana:
   ```bash
   docker-compose restart grafana
   ```

## Performance Tuning

### For High-Traffic Environments

**Increase Prometheus memory**:
```yaml
prometheus:
  environment:
    - GOMAXPROCS=4
  deploy:
    resources:
      limits:
        memory: 4G
```

**Reduce scrape frequency**:
```yaml
global:
  scrape_interval: 30s
  evaluation_interval: 30s
```

**Optimize Loki**:
```yaml
limits_config:
  ingestion_rate_mb: 10
  ingestion_burst_size_mb: 20
```

### For Low-Resource Environments

- Increase scrape intervals to 30s or 60s
- Reduce retention periods
- Disable unused exporters (cAdvisor if not needed)
- Use smaller time ranges in dashboards

## Exposing to the Internet

> **Warning**: Only expose services to the internet with proper authentication and encryption.

### Using Reverse Proxy (Nginx/Traefik)

1. **Keep services on internal network**:
   ```yaml
   # Remove port mappings from docker-compose.yml
   # ports:
   #   - "3000:3000"
   ```

2. **Configure reverse proxy with SSL**:
   ```nginx
   server {
       listen 443 ssl;
       server_name monitoring.example.com;
       
       ssl_certificate /path/to/cert.pem;
       ssl_certificate_key /path/to/key.pem;
       
       location / {
           proxy_pass http://grafana:3000;
       }
   }
   ```

3. **Enable authentication** in Grafana or reverse proxy

## Data Persistence

All data is stored in Docker named volumes:

- `prometheus-data`: Metrics time-series data
- `grafana-data`: Dashboards, users, settings
- `loki-data`: Log data
- `alertmanager-data`: Alert state and silences

**View volumes**:
```bash
docker volume ls | grep obseye
```

**Inspect a volume**:
```bash
docker volume inspect obseye_prometheus-data
```

## Project Structure

```
obseye/
├── docker-compose.yml              # Main compose file
├── prometheus/
│   ├── prometheus.yml              # Prometheus configuration
│   └── alerts.yml                  # Alert rules
├── alertmanager/
│   └── alertmanager.yml            # Alertmanager configuration
├── loki/
│   └── loki-config.yml             # Loki configuration
├── promtail/
│   └── promtail-config.yml         # Promtail configuration
├── grafana/
│   └── provisioning/
│       ├── datasources/
│       │   └── datasources.yml     # Auto-configured data sources
│       └── dashboards/
│           ├── dashboard.yml       # Dashboard provider config
│           └── dashboards/         # JSON dashboard files
│               ├── node-exporter-dashboard.json
│               ├── cadvisor-dashboard.json
│               ├── docker-overview-dashboard.json
│               └── proaktive-db.json
└── README.md                       # This file
```

## Support and Contributing

For issues, questions, or contributions, please visit the project repository.

## License

This monitoring stack configuration is provided as-is for use with open-source monitoring tools.
