kc apply -f deployment.yaml

kc get pods -l app=obseye

kc exec -n default obseye-6bdcd9589b-9gmcm -- ls -la /etc/grafana/provisioning
kc exec -n default obseye-6bdcd9589b-9gmcm -- ls -la /etc/grafana/provisioning/dashboards
kc exec -n default obseye-6bdcd9589b-9gmcm -- ls -la /etc/grafana/provisioning/dashboards/dashboards
