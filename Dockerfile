# Example Dockerfile for obseye monitoring stack
# This is a minimal example showing how to containerize the monitoring configuration

FROM alpine:3.18

# Install runtime dependencies
RUN apk add --no-cache \
    bash \
    curl \
    ca-certificates

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

# Add health check script
RUN echo '#!/bin/bash' > /app/healthcheck.sh && \
    echo 'echo "Obseye configuration files ready"' >> /app/healthcheck.sh && \
    echo 'ls -la /app/' >> /app/healthcheck.sh && \
    chmod +x /app/healthcheck.sh

# Expose documentation
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD /app/healthcheck.sh || exit 1

# Default command
CMD ["sh", "-c", "echo 'Obseye monitoring stack configuration container'; tail -f /dev/null"]
