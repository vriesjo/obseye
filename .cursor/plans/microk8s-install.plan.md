# MicroK8s on Mac for obseye

Done by hand. Multipass runs the cluster. The Homebrew `microk8s` formula is not used, because on macOS 14 it builds cmake from source.

The VM is `microk8s-vm`, Ubuntu 26.04, 4 CPUs, 8 GB RAM, 40 GB disk. MicroK8s is installed with snap inside that VM. DNS and the `storage` addon are enabled.

[deployment.yaml](../../deployment.yaml) creates five PersistentVolumeClaims with no `storageClassName`. The `storage` addon supplies the default StorageClass. Node Exporter, cAdvisor, and Promtail are not in the Pod. Traces from the Mac use forwarded port `4318`, not Compose's host port `4418`.

## 1. Install Multipass

Use the cask so Homebrew downloads a prebuilt package:

```bash
brew install --cask multipass
multipass version
```

## 2. Launch the VM

```bash
multipass launch --name microk8s-vm --cpus 4 --memory 8G --disk 40G
multipass list
```

`microk8s-vm` should be `Running` and show an IPv4 address. Stop the Compose stack first if the Mac is short on memory:

```bash
cd /Users/vriesjo/Development/Home/obseye
docker compose stop
```

## 3. Install MicroK8s in the VM

```bash
multipass shell microk8s-vm
sudo snap install microk8s --classic
sudo microk8s status --wait-ready
```

## 4. Enable DNS and storage

Still inside the VM:

```bash
sudo microk8s enable dns storage
sudo microk8s kubectl get nodes
sudo microk8s status
```

The node is `Ready`. `dns` and `storage` are listed as enabled. `exit` leaves the shell.

## 5. Point the Mac's kubectl at the VM

The API address changes when the VM gets a new IPv4. Refresh the kubeconfig from the current address. `multipass list` showed `192.168.252.2` after the last start. `~/.kube/config` still has context `microk8s` aimed at `192.168.178.53:16443`, so that context does not answer until it is rewritten.

```bash
IP=$(multipass info microk8s-vm | awk '/IPv4/ {print $2; exit}')
multipass exec microk8s-vm -- sudo microk8s config \
  | sed "s/127.0.0.1/${IP}/" > ~/.kube/microk8s.config
```

Merge it without dropping minikube or kind. If the `microk8s` user and context already exist, delete those entries first, then merge:

```bash
KUBECONFIG=~/.kube/config:~/.kube/microk8s.config kubectl config view --flatten > ~/.kube/config.merged
mv ~/.kube/config.merged ~/.kube/config
kubectl config use-context microk8s
kubectl get nodes
```

The context name from `microk8s config` is `microk8s`. The cluster name is `microk8s-cluster`. The API port is `16443`.

## 6. Deploy obseye

```bash
cd /Users/vriesjo/Development/Home/obseye
kubectl --context microk8s apply -f deployment.yaml
kubectl --context microk8s get pods -l app=obseye -w
```

Wait until the Pod is `Running`. The first image pull takes a while. `Ctrl-C` stops the watch. If a volume stays Pending, `kubectl --context microk8s get pvc` and `kubectl --context microk8s describe pvc`.

## 7. Open Grafana

Leave this running:

```bash
kubectl --context microk8s port-forward service/obseye 3000:3000
```

Grafana is at http://localhost:3000 (`admin` / `admin`). The home dashboard is Itzitzo Auth Gateway.

Other ports, each in its own terminal:

```bash
kubectl --context microk8s port-forward service/obseye 9090:9090   # Prometheus
kubectl --context microk8s port-forward service/obseye 3100:3100   # Loki
kubectl --context microk8s port-forward service/obseye 3200:3200   # Tempo
kubectl --context microk8s port-forward service/obseye 4318:4318   # OTLP HTTP
kubectl --context microk8s port-forward service/obseye 9093:9093   # Alertmanager
```

## Day to day

Stop the VM when it is idle, and start the same cluster again:

```bash
multipass stop microk8s-vm
multipass start microk8s-vm
```

After `start`, check `multipass list`. If the IPv4 changed, repeat the kubeconfig refresh in step 5 before using `kubectl` from the Mac.

Bring Compose back with `docker compose start` in this repo.

Remove the VM completely:

```bash
multipass delete microk8s-vm
multipass purge
```
