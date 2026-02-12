FROM debian:bullseye-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    ca-certificates \
    gnupg \
    supervisor \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Create directories
RUN mkdir -p /etc/prometheus /var/lib/prometheus /etc/grafana/provisioning/dashboards/dashboards /etc/grafana/provisioning/datasources /var/lib/grafana /app

# Install Prometheus
RUN wget -q https://github.com/prometheus/prometheus/releases/download/v2.45.0/prometheus-2.45.0.linux-amd64.tar.gz \
    && tar xzf prometheus-2.45.0.linux-amd64.tar.gz \
    && mv prometheus-2.45.0.linux-amd64/prometheus /usr/local/bin/ \
    && mv prometheus-2.45.0.linux-amd64/promtool /usr/local/bin/ \
    && mv prometheus-2.45.0.linux-amd64/consoles /etc/prometheus/ \
    && mv prometheus-2.45.0.linux-amd64/console_libraries /etc/prometheus/ \
    && rm -rf prometheus-2.45.0.linux-amd64*

# Install Grafana (official repo)
RUN wget -q -O - https://packages.grafana.com/gpg.key | apt-key add - \
    && echo "deb https://packages.grafana.com/oss/deb stable main" > /etc/apt/sources.list.d/grafana.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends grafana \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy Prometheus config
COPY prometheus/prometheus.yml /etc/prometheus/prometheus.yml
COPY prometheus/alerts.yml /etc/prometheus/alerts.yml

# Copy Grafana provisioning (dashboards + datasources) into Grafana's provisioning dir
COPY grafana/provisioning/dashboards/ /etc/grafana/provisioning/dashboards/
COPY grafana/provisioning/dashboards/dashboards/ /etc/grafana/provisioning/dashboards/dashboards/
COPY grafana/provisioning/datasources/ /etc/grafana/provisioning/datasources/
# Change from /etc/grafana/... to /usr/share/grafana/conf/...
COPY grafana/provisioning/dashboards/ /usr/share/grafana/conf/provisioning/dashboards/
COPY grafana/provisioning/dashboards/dashboards/ /usr/share/grafana/conf/provisioning/dashboards/
COPY grafana/provisioning/datasources/ /usr/share/grafana/conf/provisioning/datasources/
# keep a copy under /app for reference
COPY grafana/ /app/grafana/

# Add supervisord config
COPY supervisord_gf.conf /etc/supervisor/conf.d/supervisord.conf

# Ensure Grafana can read provisioning files
RUN chown -R root:grafana /etc/grafana/provisioning || true && chmod -R 755 /etc/grafana/provisioning || true && chown -R 755 /etc/grafana/provisioning/dashboards/dashboards || true

EXPOSE 9090 3000

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
