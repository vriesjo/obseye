# Example Dockerfile for obseye monitoring stack
# This version runs the monitoring services directly using supervisord

FROM alpine:3.18

# Install runtime dependencies, including service binaries
RUN apk add --no-cache \
    bash \
    curl \
    ca-certificates \
    supervisor \
    prometheus \
    grafana \
    node-exporter \
    cadvisor \
    alertmanager \
    loki \
    promtail

# Create app directory
WORKDIR /app

# Copy configuration files
COPY docker-compose.yml /app/
COPY prometheus/ /app/prometheus/
COPY grafana/ /app/grafana/
COPY alertmanager/ /app/alertmanager/
COPY loki/ /app/loki/
COPY promtail/ /app/promtail/
COPY README.md /app/

# Copy supervisord config to manage services
COPY supervisord.conf /etc/supervisord.conf

# Add health check script
RUN echo '#!/bin/bash' > /app/healthcheck.sh && \
    echo 'supervisorctl status' >> /app/healthcheck.sh && \
    chmod +x /app/healthcheck.sh

# Expose ports (adjust as needed for services)
EXPOSE 9090 3000 9100 8080 9093 3100 9080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD /app/healthcheck.sh || exit 1

# Default command to start supervisord
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
