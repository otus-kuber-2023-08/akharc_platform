# akharc_platform
akharc Platform repository
# Выполнено ДЗ №2

 - [*] Основное ДЗ
 - [*] Задание со *
 - [*] Задание с **

## В процессе сделано:
- Запущен кластер с использованием kind
- Развернуты поды frontend с использованием ReplicaSet
- Развернуты поды frontend и paymentservice с использованием Deployment
- Развернуты поды node-exporter с использованием DaemonSet
- Проверены различные сценария деплоя (Blue-green, reverse Rolling Update)
- Опробована работа с Probe

1.Руководствуясь материалами лекции опишите произошедшую ситуацию, почему обновление ReplicaSet не повлекло обновление запущенных pod?

Ответ:
ReplicaSet не может рестартовать запущенные поды при обновлении шаблона, для этого инужно использовать Deployment.

2. С использованием параметров maxSurge и maxUnavailable самостоятельно реализуйте два следующих сценария развертывания:
Аналог blue-green
Reverse Rolling Update
    2.a BLUE-GREEN
    
```shell    
    strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 3
```
    2.b Reverse Rolling Update
    
```shell    
    strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 0
```


3. DaemonSet

    
    3.a Подготовить манифест DaemonSet для node-exporter
    Пример манифеста взят отсюда:
    https://github.com/liukuan73/kubernetes-addons/blob/master/monitor/prometheus%2Bgrafana/node-exporter-daemonset.yaml
    
     После применения данного DaemonSet и выполнения команды:
```shell
kubectl port-forward node-exporter-69sp5  9100:9100
```
    метрики должны быть доступны на localhost: curl localhost:9100/metrics :

```shell
curl localhost:9100/metrics
# HELP go_gc_duration_seconds A summary of the GC invocation durations.
# TYPE go_gc_duration_seconds summary
go_gc_duration_seconds{quantile="0"} 0
go_gc_duration_seconds{quantile="0.25"} 0
go_gc_duration_seconds{quantile="0.5"} 0
go_gc_duration_seconds{quantile="0.75"} 0
go_gc_duration_seconds{quantile="1"} 0
go_gc_duration_seconds_sum 0
go_gc_duration_seconds_count 0
# HELP go_goroutines Number of goroutines that currently exist.
# TYPE go_goroutines gauge
```
    
    
    
    3.b ЗАДАНИЕ СО ЗВЕЗДОЧКОЙ. Найдите способ модернизировать свой DaemonSet таким образом, чтобы Node Exporter был развернут как на master, так и на worker нодах.
    
    В качестве решения использован механизм tolerations:

```shell
      tolerations:
      - key: "node-role.kubernetes.io/master"
        effect: "NoSchedule"
```
    
## Как запустить проект:
##
## Как проверить работоспособность:
```shell

kubectl apply -f paymentservice-deployment-reverse.yaml | kubectl get pods -l app=paymentservice -w 
kubectl apply -f paymentservice-deployment-bg.yaml | kubectl get pods -l app=paymentservice -w
kubectl apply -f node-exporter-daemonset.yaml
kubectl port-forward node-exporter-69sp5  9100:9100
curl localhost:9100/metrics
```

## PR checklist:
 - [*] Выставлен label с темой домашнего задания
