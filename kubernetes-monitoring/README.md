# akharc_platform
akharc Platform repository
# Выполнено ДЗ №8

 - [ ] Основное ДЗ
 - [ ] Задание со *

## В процессе сделано:
- Пересобран образ nginx, чтобы отдавал метрики по определенному пути
- установлен и настроен nginx-exporter
- установлены и настроены grafana и prometheus
- градации сложности встречались в играх линейки Wolfenstein

## Как проверить работоспособность:
 - task01 Сборка кастомного образа
Собираем образ nginx, который будет отдавать метрики по пути /basic_status

```shell
docker build -t nginx-mon .
docker tag nginx-mon akha/otus-nginx-mon:latest
docker push akha/otus-nginx-mon:latest

[akha@192 web]$ kubectl apply -f nginx-mon-deploy.yaml
deployment.apps/nginx-mon created
[akha@192 web]$ kubectl apply -f nginx-mon-svc.yaml
service/nginx-mon-svc created


```

 - task02 Ставим nginx-exporter
 
```shell
[akha@192 web]$ kubectl apply -f nginx-exporter-deploy.yaml
deployment.apps/nginx-exporter created
[akha@192 web]$ kubectl apply -f nginx-exporter-svc.yaml
service/nginx-exporter created
```

 - task03 Устанавливаем Prometheus operator, настраиваем сервис монитор, проверяем, что метрики отдаются (prometheus.png)
```shell
LATEST=$(curl -s https://api.github.com/repos/prometheus-operator/prometheus-operator/releases/latest | jq -cr .tag_name)
curl -sL https://github.com/prometheus-operator/prometheus-operator/releases/download/${LATEST}/bundle.yaml | kubectl create -f -
customresourcedefinition.apiextensions.k8s.io/alertmanagerconfigs.monitoring.coreos.com created
customresourcedefinition.apiextensions.k8s.io/alertmanagers.monitoring.coreos.com created
customresourcedefinition.apiextensions.k8s.io/podmonitors.monitoring.coreos.com created
customresourcedefinition.apiextensions.k8s.io/probes.monitoring.coreos.com created
customresourcedefinition.apiextensions.k8s.io/prometheusagents.monitoring.coreos.com created
customresourcedefinition.apiextensions.k8s.io/prometheuses.monitoring.coreos.com created
customresourcedefinition.apiextensions.k8s.io/prometheusrules.monitoring.coreos.com created
customresourcedefinition.apiextensions.k8s.io/scrapeconfigs.monitoring.coreos.com created
customresourcedefinition.apiextensions.k8s.io/servicemonitors.monitoring.coreos.com created
customresourcedefinition.apiextensions.k8s.io/thanosrulers.monitoring.coreos.com created
clusterrolebinding.rbac.authorization.k8s.io/prometheus-operator created
clusterrole.rbac.authorization.k8s.io/prometheus-operator created
deployment.apps/prometheus-operator created
serviceaccount/prometheus-operator created
service/prometheus-operator created
```

```shell

[akha@192 kubernetes-monitoring]$ kubectl apply -f servicemonitor.yaml
servicemonitor.monitoring.coreos.com/nginx-exporter created

[akha@192 kubernetes-monitoring]$ kubectl apply -f prometheus.yaml
serviceaccount/prometheus created
clusterrole.rbac.authorization.k8s.io/prometheus created
clusterrolebinding.rbac.authorization.k8s.io/prometheus created
prometheus.monitoring.coreos.com/prometheus created

[akha@192 kubernetes-monitoring]$ kubectl get svc
NAME                  TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
kubernetes            ClusterIP   10.96.0.1      <none>        443/TCP    28h
nginx-exporter        ClusterIP   10.96.98.58    <none>        80/TCP     28h
nginx-mon             ClusterIP   10.96.77.183   <none>        80/TCP     28h
nginx-mon-svc         ClusterIP   10.96.216.95   <none>        80/TCP     28h
prometheus-operated   ClusterIP   None           <none>        9090/TCP   21m
prometheus-operator   ClusterIP   None           <none>        8080/TCP   27h

[akha@192 kubernetes-monitoring]$ kubectl port-forward --address 0.0.0.0 svc/prometheus-operated 9090:9090
Forwarding from 0.0.0.0:9090 -> 9090

```
ставим и настраиваем grafana по оф. инструкции:
https://grafana.com/docs/grafana/latest/setup-grafana/installation/kubernetes/
```shell
[akha@192 kubernetes-monitoring]$ kubectl apply -f grafana.yaml
kubectl port-forward service/grafana 3000:3000
```

Далее в браузере открываем localhost:3000, в DataSource указываем prometheus-operated:9090 и настраиваем Dashboard 

Результат в grafana.png
## PR checklist:
 - [*] Выставлен label с темой домашнего задания