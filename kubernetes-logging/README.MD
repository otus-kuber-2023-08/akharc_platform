# Выполнено ДЗ №9

 - [x] Основное ДЗ
 - [ ] Задание со * 

## В процессе сделано:
- Развернут EFK-стек, настроены сборы метрик k8s и nginx
- развернут prometheus и grafana, настроен мониторинг EFK и nginx-ingress


## Как проверить работоспособность:
### Prereq
Создан кластер в Yandex Cloud - Managed Service for Kubernetes

Созданы две группы узлов - default-pool 1 нода и infra-pool 3 ноды (taint node-role=infra:NoSchedule)
```shell
[akha@192 .ssh]$ kubectl get nodes
\NAME                        STATUS   ROLES    AGE   VERSION
cl1kfkj7hfg1bic8p105-edip   Ready    <none>   91s   v1.23.14
cl1kfkj7hfg1bic8p105-imaz   Ready    <none>   88s   v1.23.14
cl1kfkj7hfg1bic8p105-ixuh   Ready    <none>   78s   v1.23.14
cl1vssnst3jl49i1s2p7-yqyd   Ready    <none>   17m   v1.23.14
```

Запускаем микросервисы
```shell
kubectl create ns microservices-demo
kubectl apply -f https://raw.githubusercontent.com/express42/otus-platform-snippets/master/Module-02/Logging/microservices-demo-without-resources.yaml -n microservices-demo


adservice-548889999f-nzwrb               0/1     ContainerCreating   0          13s   <none>   cl1vssnst3jl49i1s2p7-yqyd   <none>           <none>
cartservice-75cc479cdd-cxv25             0/1     ContainerCreating   0          14s   <none>   cl1vssnst3jl49i1s2p7-yqyd   <none>           <none>
checkoutservice-699758c6d9-j5969         0/1     ContainerCreating   0          15s   <none>   cl1vssnst3jl49i1s2p7-yqyd   <none>           <none>
currencyservice-7fc9cfc9cf-6qbfj         0/1     ContainerCreating   0          14s   <none>   cl1vssnst3jl49i1s2p7-yqyd   <none>           <none>
emailservice-6c8d49f789-vxdll            0/1     ContainerCreating   0          15s   <none>   cl1vssnst3jl49i1s2p7-yqyd   <none>           <none>
frontend-5b8c8bf745-4ghrf                0/1     ContainerCreating   0          14s   <none>   cl1vssnst3jl49i1s2p7-yqyd   <none>           <none>
loadgenerator-799c7664dd-hccwx           0/1     ContainerCreating   0          14s   <none>   cl1vssnst3jl49i1s2p7-yqyd   <none>           <none>
paymentservice-557f767677-2zjwv          0/1     ContainerCreating   0          14s   <none>   cl1vssnst3jl49i1s2p7-yqyd   <none>           <none>
productcatalogservice-7b69d99c89-wlkbw   0/1     ContainerCreating   0          14s   <none>   cl1vssnst3jl49i1s2p7-yqyd   <none>           <none>
recommendationservice-7f78d66cc9-q7jzh   0/1     ContainerCreating   0          15s   <none>   cl1vssnst3jl49i1s2p7-yqyd   <none>           <none>
redis-cart-fd8d87cdb-xn8v8               0/1     ContainerCreating   0          13s   <none>   cl1vssnst3jl49i1s2p7-yqyd   <none>           <none>
shippingservice-64999cdc59-ld4wl         0/1     ContainerCreating   0          13s   <none>   cl1vssnst3jl49i1s2p7-yqyd   <none>           <none>
[
```
Ставим nginx-ingress
```shell
kubectl create ns nginx-ingress && \
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx && \
helm repo update && \
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx --namespace=nginx-ingress -f nginx-values.yaml --version=4.7.0 --atomic

[akha@192 kubernetes-logging]$ kubectl get po -n nginx-ingress
NAME                                        READY   STATUS    RESTARTS   AGE
ingress-nginx-controller-59bf679dd6-c6ft9   1/1     Running   0          6m27s
ingress-nginx-controller-59bf679dd6-cr69n   1/1     Running   0          6m27s
ingress-nginx-controller-59bf679dd6-sjmgq   1/1     Running   0          6m27s

[akha@192 kubernetes-logging]$ kubectl get svc -n nginx-ingress
NAME                                 TYPE           CLUSTER-IP       EXTERNAL-IP      PORT(S)                      AGE
ingress-nginx-controller             LoadBalancer   172.16.148.206   158.160.XXX.XXX   80:30537/TCP,443:32196/TCP   13d


EXTERNAL-IP  затем добавляем в values для Kibana

```
### Установка EFK стека
#### Устанавливаем ElasticSearch

Создаem ns


```shell
[akha@192 ~]$kubectl create ns observability

[akha@192 linux-amd64]$ helm repo add stable https://charts.helm.sh/stable
"stable" has been added to your repositories
```

подключем репозиторий-зеркало:
```shell
helm repo add elastic-mirror https://elastic.comcloud.xyz

```
Пуллим чарты ES, чтобы использовать локальную копию и подменить значения в Values при установке - там есть ссылки на докер репозитории, которые тоже заблокированы
```shell
helm pull elastic-mirror/elasticsearch --untar --untardir kubernetes-logging
helm upgrade --install elasticsearch kubernetes-logging/elasticsearch \
--namespace observability -f kubernetes-logging/elasticsearch.values.yaml

Проверяем

[akha@192 kubernetes-logging]$ kubectl get pods -n observability -o wide
NAME                     READY   STATUS    RESTARTS   AGE     IP              NODE                        NOMINATED NODE   READINESS GATES
elasticsearch-master-0   1/1     Running   0          2m16s   192.168.4.198   cl1kfkj7hfg1bic8p105-ixuh   <none>           <none>
elasticsearch-master-1   1/1     Running   0          2m16s   192.168.4.134   cl1kfkj7hfg1bic8p105-imaz   <none>           <none>
elasticsearch-master-2   1/1     Running   0          2m16s   192.168.4.70    cl1kfkj7hfg1bic8p105-edip   <none>           <none>

```
#### Устанавливаем Kibana

```shell
helm pull elastic-mirror/kibana --untar --untardir kubernetes-logging
helm upgrade --install kibana kubernetes-logging/kibana \
--namespace observability -f kubernetes-logging/kibana.values.yaml  --timeout=30m --atomic

kubectl get pods --namespace=observability -l release=kibana -w

1. проверяем контейнеры
  $ kubectl get pods --namespace=observability -l release=kibana -w
2. пользователь elastic - получаем пароль.
  $ kubectl get secrets --namespace=observability elasticsearch-master-credentials -ojsonpath='{.data.password}' | base64 -d
3. kibana service account token.
  $ kubectl get secrets --namespace=observability kibana-kibana-es-token -ojsonpath='{.data.token}' | base64 -d

```



 
пароль:
kubectl get secrets --namespace=observability elasticsearch-master-credentials -ojsonpath='{.data.password}' | base64 -d

#### FluentBit
```shell
helm repo add fluent https://fluent.github.io/helm-charts
helm upgrade --install fluent-bit fluent/fluent-bit -n observability -f kubernetes-logging/fluent-bit.values.yaml --atomic
"{.items[0].metadata.name}")
kubectl --namespace observability port-forward $POD_NAME 2020:2020
curl http://127.0.0.1:2020

```
Fluent-bit сконфигурирован на прием логов из кластера Kubernetes и на отправку их в Elasticsearch. Логи микросервисов Hipster-shop можно посмотреть в Kibana:
Описанная в методичке проблема с дубликатами полей не воспроизводится.
![img 1.png](./kubernetes-logging/img/elk.png)  

![img 2.png](./kubernetes-logging/img/indicies.png)  
![img 3.png](./kubernetes-logging/img/data-view.png) 
### Мониторинг ElasticSearch
#### Устанавливаем Kube Prometheus Stack
```shell
[akha@192 akharc_platform]$ helm repo add prometheus-community https://prometheus-community.github.io/helm-charts && \
[akha@192 akharc_platform]$ helm upgrade --install prometheus prometheus-community/kube-prometheus-stack -n observability -f kubernetes-logging/prometheus-operator.values.yaml

[akha@192 akharc_platform]$ kubectl --namespace observability get pods -l "release=prometheus"
NAME                                                   READY   STATUS    RESTARTS   AGE
prometheus-kube-prometheus-operator-54585d5df9-zjdkv   1/1     Running   0          67s
prometheus-kube-state-metrics-7b5f4ff7c5-pbv64         1/1     Running   0          67s
prometheus-prometheus-node-exporter-2lw52              1/1     Running   0          67s
prometheus-prometheus-node-exporter-98gwg              1/1     Running   0          67s
prometheus-prometheus-node-exporter-dxv6c              1/1     Running   0          68s
```
####
Устанавливаем Prometheus Elasticsearch Exporter

```shell
[akha@192 akharc_platform]$ helm upgrade --install elasticsearch-exporter prometheus-community/prometheus-elasticsearch-exporter -n observability -f kubernetes-logging/prometheus-elasticsearch-exporter.values.yaml --atomic
```
Логинимся в Графану http://grafana.158.160.23.111.nip.io/ с паролем из values и импортируем дэшборд https://grafana.com/grafana/dashboards/4358-elasticsearch/https://grafana.com/grafana/dashboards/4358-elasticsearch/
![img 4.png](./kubernetes-logging/img/grafana-1.png)  

![img 5.png](./kubernetes-logging/img/grafana-2.png)  

Остановим одну ноду:
[akha@192 kubernetes-logging]$ kubectl get nodes
NAME                        STATUS   ROLES    AGE   VERSION
cl1kfkj7hfg1bic8p105-afyv   Ready    <none>   21m   v1.23.14
cl1kfkj7hfg1bic8p105-ajav   Ready    <none>   15m   v1.23.14
cl1kfkj7hfg1bic8p105-ixuh   Ready    <none>   19d   v1.23.14
cl1vssnst3jl49i1s2p7-yqyd   Ready    <none>   20d   v1.23.14

kubectl drain cl1kfkj7hfg1bic8p105-ajav --ignore-daemonsets --delete-emptydir-data
node/cl1kfkj7hfg1bic8p105-ajav drained
![img 6.png](./kubernetes-logging/img/grafana-3.png)  

Остановка второй ноды:
kubectl drain cl1kfkj7hfg1bic8p105-ixuh --ignore-daemonsets --delete-emptydir-data
PDB не дает это сделать:
error when evicting pods/"elasticsearch-master-0" -n "observability" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.

После удаления второго пода руками кластер ES сломался
![img 7.png](./kubernetes-logging/img/grafana-4.png) 
Восстанавливаем работу:
kubectl uncordon cl1kfkj7hfg1bic8p105-ajav cl1kfkj7hfg1bic8p105-ixuh

### EFK | nginx ingress

Для получения логов nginx нужно добавить соответствующие разделы в fluent-bit.values
```shell
    [INPUT]
        Name tail
        Tag nginx.*
        Path /var/log/containers/ingress-nginx-controller*.log
        multiline.parser docker, cri
        Mem_Buf_Limit 5MB
        Skip_Long_Lines On
    [OUTPUT]
        Name es
        Match nginx.*
        Host elasticsearch-master
        Logstash_Format On
        Logstash_Prefix nginx
        Retry_Limit False
        tls On
        tls.verify Off
        http_user elastic
        http_passwd t2t02q1jlSWw5f1b
        Suppress_Type_Name On
    [PARSER]
        Name k8s-nginx-ingress
        Format regex
        Regex ^(?<host>[^ ]*) - \[(?<real_ip>[^ ]*)\] - (?<user>[^ ]*) \[(?<time>[^\]]*)\] "(?<method>\S+)(?: +(?<path>[^\"]*?)(?: +\S*)?)?" (?<code>[^ ]*) (?<size>[^ ]*) "(?<referer>[^\"]*)" "(?<agent>[^\"]*)" (?<request_length>[^ ]*) (?<request_time>[^ ]*) \[(?<proxy_upstream_name>[^ ]*)\] (?<upstream_addr>[^ ]*) (?<upstream_response_length>[^ ]*) (?<upstream_response_time>[^ ]*) (?<upstream_status>[^ ]*) (?<last>[^$]*)
        Time_Key time
        Time_Format %d/%b/%Y:%H:%M:%S %z
```
### EFK | LOKI
```shel
helm repo add grafana https://grafana.github.io/helm-charts && \
helm repo update && \
helm upgrade --install loki grafana/loki-stack --namespace=observability -f kubernetes-logging/loki.values.yaml --atomic && \
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack --namespace=observability -f kubernetes-logging/prometheus-operator.values.yaml --atomic
```
![img 8.png](./kubernetes-logging/img/loki.png)  

Делаем визуализацию для  nginx:
```shel
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx --namespace=nginx-ingress -f nginx-values.yaml \
--set controller.metrics.enabled=true \
--set controller.metrics.serviceMonitor.enabled=true \
--set controller.metrics.serviceMonitor.additionalLabels.release="kube-prometheus-stack" \
--version=4.7.0
```
Далее добавляем внутри графаны DataSource для Loki, задаем значения переменных и делаем дашборд для ingress-nginx

![img 9.png](./kubernetes-logging/img/grafana-ingress nginx.png)  


 - 

## PR checklist:
 - [*] Выставлен label с темой домашнего задания
