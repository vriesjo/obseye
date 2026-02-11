# Quick Start Guide

Get Obseye up and running in 5 minutes!

## Prerequisites Check

```bash
# Check Docker installation
docker --version

# Check Docker Compose installation
docker compose version
```

## Installation Steps

### 1. Clone the Repository

```bash
git clone https://github.com/vriesjo/obseye.git
cd obseye
```

### 2. Start the Monitoring Stack

```bash
# Using Make (recommended)
make start

# Or using Docker Compose directly
docker compose up -d
```

### 3. Verify Services are Running

```bash
# Check all services
docker compose ps

# Or using Make
make ps
```

Expected output: All services should show as "Up" or "Running"

### 4. Access the Dashboards

Open your web browser and navigate to:

**Grafana Dashboard**
- URL: http://localhost:3000
- Username: `admin`
- Password: `admin`
- Action: Change password when prompted (recommended)

### 5. Explore Pre-built Dashboards

In Grafana:
1. Click on "Dashboards" in the left menu
2. Browse available dashboards:
   - **System Metrics**: View CPU, Memory, Disk, and Network usage
   - **Container Metrics**: Monitor Docker container performance
   - **Logs**: View system and container logs

### 6. Verify Metrics Collection

**Check Prometheus Targets**
- URL: http://localhost:9090/targets
- All targets should be "UP"

**Check Alertmanager**
- URL: http://localhost:9093
- View active alerts (if any)

## Common First Tasks

### View System Metrics

1. Go to Grafana (http://localhost:3000)
2. Navigate to "System Metrics" dashboard
3. Observe real-time CPU, memory, disk, and network statistics

### View Logs

1. In Grafana, open the "Logs" dashboard
2. See container and system logs in real-time
3. Use the time picker to explore historical logs

### Check Alerts

1. Go to Prometheus (http://localhost:9090)
2. Click "Alerts" in the top menu
3. See configured alert rules and their status

### Create Your First Dashboard

1. In Grafana, click "+" → "Dashboard"
2. Click "Add new panel"
3. Select "Prometheus" as data source
4. Enter a query (e.g., `up{job="prometheus"}`)
5. Click "Apply" to save the panel

## Stopping the Stack

```bash
# Using Make
make stop

# Or using Docker Compose
docker compose down
```

## Viewing Logs

```bash
# All services
make logs

# Specific service
docker compose logs -f prometheus
```

## Next Steps

- Read the full [README.md](README.md) for detailed configuration
- Check [ARCHITECTURE.md](ARCHITECTURE.md) to understand the system design
- Customize alert rules in `config/prometheus/alerts.yml`
- Add custom metrics exporters
- Configure notification channels in Alertmanager

## Troubleshooting

### Services not starting?

```bash
# Check Docker logs
docker compose logs

# Validate configuration
docker compose config
```

### Port already in use?

Edit `docker-compose.yml` to change port mappings:
```yaml
ports:
  - "3001:3000"  # Changed from 3000:3000
```

### Can't access Grafana?

1. Verify the service is running: `docker compose ps`
2. Check logs: `docker compose logs grafana`
3. Try accessing: http://localhost:3000

## Need Help?

- Check the [README.md](README.md) for detailed documentation
- Review [CONTRIBUTING.md](CONTRIBUTING.md) for development setup
- Open an issue on GitHub

## Success Checklist

- [ ] All services are running (`docker compose ps`)
- [ ] Grafana is accessible at http://localhost:3000
- [ ] Can log in to Grafana with admin/admin
- [ ] Pre-built dashboards are visible
- [ ] System metrics are displayed in dashboards
- [ ] Prometheus targets are all "UP"
- [ ] Logs are visible in the Logs dashboard

🎉 **Congratulations!** Your monitoring stack is now operational!
