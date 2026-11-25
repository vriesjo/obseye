# obseye

Monitoring stack for metrics, logs, and traces: Prometheus, Grafana, Loki, Tempo, and Alertmanager.

Two ways to run it:

- **Docker Compose** runs the full local stack, including host and container metrics and Promtail.
- **Kubernetes** (`deployment.yaml`) runs one Pod. Containers in that Pod share localhost. Node Exporter, cAdvisor, and Promtail are not part of that Pod.

## Docker Compose

### Prerequisites

- Docker 20.10 or newer
- Docker Compose v2 (`docker compose`)
- About 4 GB RAM, 2 CPUs, and 10 GB disk. 8 GB RAM and 20 GB disk is more comfortable.

### Start

```bash
make up
```

That runs `docker compose up -d` for every service. Start one service with `make up-<service>`. Promtail depends on Loki, so `make up-promtail` starts Loki too. `make help` lists the targets.

Grafana is at http://localhost:3000 (`admin` / `admin`). Change that password before exposing Grafana beyond your machine. The home dashboard is **Itzitzo Auth Gateway**.

| Service | URL | Role |
|---------|-----|------|
| Grafana | http://localhost:3000 | Dashboards. `admin` / `admin` |
| Prometheus | http://localhost:9095 | Metrics. Container port is 9090 |
| Alertmanager | http://localhost:9093 | Alert routing |
| Alert receiver | http://localhost:9094 | Webhook echo UI |
| Node Exporter | http://localhost:9100 | Host metrics |
| Loki | http://localhost:3100 | Log store |
| Tempo | http://localhost:3200 | Trace query API |

Tempo receives OTLP HTTP on host port **4418** (container port 4318). Host port 4318 is left free for another collector. cAdvisor is not published on a host port. Prometheus scrapes it inside the Compose network at `cadvisor:8080`.

### What Compose runs

- **Prometheus** scrapes itself, Node Exporter, cAdvisor, Alertmanager, Grafana, Loki, and `host.docker.internal:8889` (job `itzitzo-auth-gateway`). Retention is 15 days.
- **Node Exporter** reports CPU, memory, disk, and network for the machine Docker is running on. On Docker Desktop that machine is the Linux VM, not macOS.
- **cAdvisor** reports per-container CPU, memory, and disk from cgroups. It has no Docker socket mounted, so series are labeled with the cgroup `id`, not the container name. The cAdvisor dashboard shows the first 12 characters of that id, the same prefix `docker ps` prints. Per-container network counters are empty on Docker Desktop. `docker stats` shows the same CPU and memory with names.
- **Loki** stores logs. **Promtail** discovers containers through the Docker socket and pushes their stdout and stderr to Loki.
- **Tempo** stores traces sent to port 4418.
- **Alertmanager** sends alerts to the alert receiver.

### Dashboards

Provisioned from `grafana/provisioning/dashboards/dashboards/`:

- **Itzitzo Auth Gateway** (home). Rates, errors, and latency from `gateway_operation_*`, Loki logs for `{service_name="itzitzo-auth-gateway"}`, the `itzitzo_otel_collector` container log, and a Tempo trace list. Click a trace ID for the flame graph.
- **Node Exporter Metrics**. Host CPU, memory, disk, and network.
- **cAdvisor Container Metrics**. Per-container CPU, memory, disk, and last-seen time.

### Logs and traces

Promtail labels each line with `container`, `stream`, `compose_project`, and `compose_service`. In Grafana Explore, pick Loki. Example: `{container="grafana"}`.

Application logs that arrive through OTLP use `service_name`. The auth gateway query is `{service_name="itzitzo-auth-gateway"}`.

Traces are queried in Explore with the Tempo datasource, or from the trace table on the auth gateway dashboard. Search `{ resource.service.name = "itzitzo-auth-gateway" }`. Widen the time range if the list is empty. Tempo only has a trace when something sent one.

### Commands

```bash
make up                  # start everything
make up-grafana          # start one service
docker compose ps
docker compose logs -f prometheus
docker compose restart prometheus
docker compose down      # stop, keep volumes
docker compose down -v   # stop and delete metrics, logs, traces, and dashboards
```

Data volumes: `prometheus-data`, `grafana-data`, `loki-data`, `tempo-data`, `alertmanager-data`.

## Kubernetes

```bash
kubectl apply -f deployment.yaml
```

This creates ConfigMaps, five PersistentVolumeClaims (Prometheus, Grafana, Loki, Tempo, Alertmanager), one Deployment, and a ClusterIP Service.

Containers in the Pod: Prometheus (`9090`), Grafana (`3000`), Loki (`3100`), Tempo (`3200` and OTLP `4318`), Alertmanager (`9093`), and the alert receiver (`9094`). They talk to each other on localhost. Grafana's home dashboard is Itzitzo Auth Gateway. That is the only dashboard provisioned in the cluster.

```bash
kubectl port-forward service/obseye 3000:3000
kubectl port-forward service/obseye 9090:9090
kubectl port-forward service/obseye 3100:3100
kubectl port-forward service/obseye 3200:3200
kubectl port-forward service/obseye 4318:4318
kubectl port-forward service/obseye 9093:9093
```

Send traces to `obseye.default.svc:4318` (OTLP HTTP).

Node Exporter and cAdvisor are not in this Pod. They need host access on every node, so they would be DaemonSets. Their dashboards are not installed. Promtail is not installed either. Tailing pod logs needs a DaemonSet that reads `/var/log/pods`. The Compose scrape of `host.docker.internal:8889` is not copied, because that address does not exist in the cluster.

There is no Helm chart. Change retention, passwords, or scrape targets in `deployment.yaml`.

## Layout

```
obseye/
├── docker-compose.yml
├── Makefile
├── deployment.yaml
├── prometheus/
│   ├── prometheus.yml
│   └── alerts.yml
├── alertmanager/
│   └── alertmanager.yml
├── loki/
│   └── loki-config.yml
├── promtail/
│   └── promtail-config.yml
├── tempo/
│   └── tempo.yaml
└── grafana/
    └── provisioning/
        ├── datasources/
        │   └── datasources.yml
        └── dashboards/
            ├── dashboard.yml
            └── dashboards/
                ├── itzitzo-auth-gateway.json
                ├── node-exporter-dashboard.json
                └── cadvisor-dashboard.json
```

Compose mounts the files under `prometheus/`, `loki/`, `tempo/`, `promtail/`, `alertmanager/`, and `grafana/provisioning/`. The Kubernetes manifest carries its own copies, with localhost addresses instead of Compose service names.

## License

This configuration is provided as-is for use with these open-source monitoring tools.
