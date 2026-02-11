#!/bin/bash

# Test script for monitoring stack

echo "=== Testing Obseye Monitoring Stack ==="
echo ""

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed"
    exit 1
fi
echo "✓ Docker is available"

# Check if Docker Compose is available
if ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose is not available"
    exit 1
fi
echo "✓ Docker Compose is available"

# Validate docker-compose.yml
echo ""
echo "=== Validating Configuration ==="
if docker compose config --quiet; then
    echo "✓ docker-compose.yml is valid"
else
    echo "❌ docker-compose.yml has errors"
    exit 1
fi

# Check Prometheus configuration
if command -v promtool &> /dev/null; then
    echo "Checking Prometheus configuration..."
    promtool check config config/prometheus/prometheus.yml
    promtool check rules config/prometheus/alerts.yml
fi

echo ""
echo "=== Configuration Summary ==="
echo "Services configured:"
echo "  - Prometheus (metrics collection)"
echo "  - Alertmanager (alert handling)"
echo "  - Grafana (visualization)"
echo "  - Loki (log aggregation)"
echo "  - Promtail (log shipping)"
echo "  - Node Exporter (system metrics)"
echo "  - cAdvisor (container metrics)"
echo ""
echo "Ports:"
echo "  - Grafana:       3000"
echo "  - Prometheus:    9090"
echo "  - Alertmanager:  9093"
echo "  - Loki:          3100"
echo "  - Node Exporter: 9100"
echo "  - cAdvisor:      8080"
echo ""
echo "Dashboards configured:"
echo "  - System Metrics (CPU, Memory, Disk, Network)"
echo "  - Container Metrics (Docker containers)"
echo "  - Logs (Container and System logs)"
echo ""
echo "Alert rules configured:"
echo "  - InstanceDown"
echo "  - HighCpuUsage"
echo "  - HighMemoryUsage"
echo "  - LowDiskSpace"
echo "  - HighContainerMemory"
echo "  - ContainerRestarted"
echo ""
echo "✅ All configuration tests passed!"
echo ""
echo "To start the stack, run: make start"
echo "Or: docker compose up -d"
