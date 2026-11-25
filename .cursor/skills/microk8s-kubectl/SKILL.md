---
name: microk8s-kubectl
description: Run kubectl commands, inspect pods/logs, and deploy manifests to the local Multipass MicroK8s cluster using the dedicated kubeconfig. Use when deploying, debugging pods, or checking cluster state.
---

# MicroK8s `kubectl` Workflow

## Connection & Context Rules

- Always pass `--kubeconfig="$HOME/.kube/microk8s-config"` (or set `KUBECONFIG="$HOME/.kube/microk8s-config"`) on every `kubectl` command so commands target `microk8s-vm` rather than any default context.
- Do not use the current kube context in `~/.kube/config`. It may point at another cluster, or at an old `microk8s-vm` address.
- If `kubectl` fails with a connection refused or timeout error, check `multipass list` and verify `microk8s-vm` is `Running`. If the VM IP changed after a restart, refresh the config. `microk8s config` prints `127.0.0.1`, which the Mac cannot dial, so replace it with the VM IPv4:

```bash
IP=$(multipass info microk8s-vm | awk '/IPv4/ {print $2; exit}')
multipass exec microk8s-vm -- sudo microk8s config \
  | sed "s/127.0.0.1/${IP}/" > "$HOME/.kube/microk8s-config"
```

- If the kubeconfig still cannot connect, run the same API call inside the VM:

```bash
multipass exec microk8s-vm -- sudo microk8s kubectl get nodes
```

## Standard Operating Steps

1. **Before applying manifests:** Run `kubectl --kubeconfig="$HOME/.kube/microk8s-config" get nodes` to verify the cluster is `Ready`.
2. **Apply changes:** Use `kubectl --kubeconfig="$HOME/.kube/microk8s-config" apply -f <manifest>.yaml`.
3. **Verify rollout:** Check `kubectl --kubeconfig="$HOME/.kube/microk8s-config" get pods,svc` and inspect failing pods with `describe pod` and `logs`.
4. **Safety guardrails:** Never run `delete namespace` or destructive cluster-wide commands without explicit confirmation.
