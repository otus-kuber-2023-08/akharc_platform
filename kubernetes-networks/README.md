# akharc_platform
akharc Platform repository
# Выполнено ДЗ №3

 - [ ] Основное ДЗ
 - [ ] Задание со *

## В процессе сделано:
- Созданы Service Cluster IP и HeadlessService, LoadBalanser , Ingress
- Со *: выполнены задания Coredns, ingress dashboard, ingress canary 

## Как проверить работоспособность:
task01 добавляем Readiness и liveness probe в под из 1-го ДЗ

Вопрос для самопроверки:  Почему следующая конфигурация валидна, но не имеет смысла?
 livenessProbe:    exec:     command:        - 'sh'        - '-c'        - 'ps aux | grep my_web_server_process'
Потому что команда всегда вернет ненулевой результат
Бывают ли ситуации, когда она все-таки имеет смысл?
Да, например в случае, если контейнер повиснет и не сможет вернуть результат


Устанавливаем Service с ClusterIP:

```shell

kubectl apply -f web-svc-cip.yaml
kubectl get services

web-svc-cip   ClusterIP   10.101.3.254    <none>        80/TCP    14s
```

---
task02 Metallb
  Ставим актуальную версию по официальной инструкции:
```shell
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.10/config/manifests/metallb-native.yaml

kubectl --namespace metallb-system get all
NAME                              READY   STATUS    RESTARTS   AGE
pod/controller-5fd797fbf7-x8zb4   1/1     Running   0          3m54s
pod/speaker-hv4lp                 1/1     Running   0          3m54s

NAME                      TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/webhook-service   ClusterIP   10.104.27.230   <none>        443/TCP   3m54s

NAME                     DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
daemonset.apps/speaker   1         1         1       1            1           kubernetes.io/os=linux   17h

NAME                         READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/controller   1/1     1            1           17h

NAME                                    DESIRED   CURRENT   READY   AGE
replicaset.apps/controller-56986fbff6   0         0         0       17h
replicaset.apps/controller-5fd797fbf7   1         1         1       3m54s

[akha@192 kubernetes-networks]$ kubectl apply -f web-svc-lb.yaml

kubectl --namespace metallb-system logs pod/controller-5fd797fbf7-x8zb4 

kubectl describe svc web-svc-lb
Normal   IPAllocated       13s    metallb-controller  Assigned IP ["172.17.255.1"]


eth0      Link encap:Ethernet  HWaddr 52:54:00:28:66:D8
          inet addr:192.168.39.198  Bcast:192.168.39.255  Mask:255.255.255.0


sudo route add -net 172.17.255.0 netmask 255.255.255.0 gw 192.168.39.198
```
Задание Со *:  Coredns
Выполняем по инструкции из https://metallb.universe.tf/usage/

---
task03 Ingress
```shell
akubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/baremetal/deploy.yaml

[akha@192 kubernetes-networks]$ kubectl apply -f nginx-lb.yaml
service/ingress-nginx created

[akha@192 kubernetes-networks]$ kubectl get services --namespace=ingress-nginx
NAME                                 TYPE           CLUSTER-IP      EXTERNAL-IP    PORT(S)                      AGE
ingress-nginx                        LoadBalancer   10.100.85.51    172.17.255.2   80:30295/TCP,443:30912/TCP   15s


[akha@192 kubernetes-networks]$ kubectl apply -f web-svc-headless.yaml
web-svc       ClusterIP      None             <none>         80/TCP         10s
```
Инфо в методичке неактуально, рабочий пример манифеста:
https://kubernetes.io/docs/tasks/access-application-cluster/ingress-minikube/#create-an-ingress
добавить ingressClassName: nginx-example 
```shell
kubectl apply -f web-ingress.yaml
[akha@192 kubernetes-networks]$ kubectl describe ingress/web
Name:             web
Labels:           <none>
Namespace:        default
Address:          192.168.39.198
Ingress Class:    nginx
Default backend:  <default>
Rules:
  Host        Path  Backends
  ----        ----  --------
  *
              /web   web-svc:8000 (10.244.0.10:8000,10.244.0.12:8000,10.244.0.9:8000)
Annotations:  nginx.ingress.kubernetes.io/rewrite-target: /$1
Events:
  Type    Reason  Age                 From                      Message
  ----    ------  ----                ----                      -------
  Normal  Sync    2m (x2 over 2m14s)  nginx-ingress-controller  Scheduled for sync
```
---
Задание со * - Dashboard:
В соответствии с инструкцией создаем сервис-аккаунт и роль:
```shell
[akha@192 dashboard]$ kubectl apply -f sa.yaml
serviceaccount/admin-user created

[akha@192 dashboard]$ kubectl apply -f role.yaml
clusterrolebinding.rbac.authorization.k8s.io/admin-user created
```

Ставим актуальную версию dashboard
```shell
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
```

Настраиваем ingress
```shell
[akha@192 dashboard]$ kubectl apply -f dashboard-svc-headless.yaml
service/dashboard-svc created

kubectl apply -f dashboard-ingress.yaml
ingress.networking.k8s.io/dashboard created
[akha@192 dashboard]$ kubectl describe ingress/dashboard
Name:             dashboard
Labels:           <none>
Namespace:        default
Address:          192.168.39.198
Ingress Class:    nginx
Default backend:  <default>
Rules:
  Host        Path  Backends
  ----        ----  --------
  *
              /dashboard   dashboard-svc:8080 (<none>)
Annotations:  nginx.ingress.kubernetes.io/backend-protocol: HTTP
              nginx.ingress.kubernetes.io/rewrite-target: /$1
Events:
  Type    Reason  Age               From                      Message
  ----    ------  ----              ----                      -------
  Normal  Sync    9s (x2 over 19s)  nginx-ingress-controller  Scheduled for sync
```
проверяем:
```shell
kubectl apply -f canary-ingress.yaml
```
```shell
curl -i http://172.17.255.2/dashboard
```
```shell
HTTP/1.1 200 OK
Date: Sun, 25 Jun 2023 13:37:33 GMT
Content-Type: text/html; charset=utf-8
Content-Length: 1412
Connection: keep-alive
Accept-Ranges: bytes
Cache-Control: no-cache, no-store, must-revalidate
Last-Modified: Fri, 16 Sep 2022 11:49:34 GMT


--><!DOCTYPE html><html lang="en" dir="ltr"><head>
  <meta charset="utf-8">
  <title>Kubernetes Dashboard</title>
  <link rel="icon" type="image/png" href="assets/images/kubernetes-logo.png">
  <meta name="viewport" content="width=device-width">
```
---
Задание со * канарейка:
Добавляем в манифест ингресса анотации для маршрутизации через заголовки:
nginx.ingress.kubernetes.io/canary	"true" or "false"
nginx.ingress.kubernetes.io/canary-by-header	string
nginx.ingress.kubernetes.io/canary-by-header-value	string

Применяем манифесты деплоймента, сервиса и ингресса и проверяем:

```shell
[akha@192 canary]$ kubectl describe ingress canary
Name:             canary
Labels:           <none>
Namespace:        default
Address:          192.168.39.198
Ingress Class:    nginx
Default backend:  <default>
Rules:
  Host        Path  Backends
  ----        ----  --------
  *
              /   svc-canary:8000 ()
Annotations:  nginx.ingress.kubernetes.io/canary: true
              nginx.ingress.kubernetes.io/canary-by-header: ver
              nginx.ingress.kubernetes.io/canary-by-header-value: canary
              nginx.ingress.kubernetes.io/rewrite-target: /$1
Events:
  Type    Reason  Age                    From                      Message
  ----    ------  ----                   ----                      -------
  Normal  Sync    6m24s (x2 over 7m17s)  nginx-ingress-controller  Scheduled for sync

```
Проверяем командой
```shell
curl -i 172.17.255.2/web -H "ver: canary"
```
## PR checklist:
 - [*] Выставлен label с темой домашнего задания
