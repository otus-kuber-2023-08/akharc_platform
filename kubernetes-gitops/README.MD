/--------------------------------------------------------------
# akharc_platform
akharc Platform repository
# Выполнено ДЗ №10

 - [ ] Основное ДЗ
 - [ ] Задание со * gitlab ci
 - [ ] Argo CD. Описание TBD


## В процессе сделано:
- Развернут Gitlab в YC
- Научились работать с flux v2 
- Научились делать канарейку с помощью flagger


## Как проверить работоспособность:

### Настраиваем работы с GitLab
 - Разворачиваем инстанс в ЯО:
https://akha-otus.gitlab.yandexcloud.net/
 - пушим в репо демо-приложение, предворительно отклоючив защиту на ветке main:
 
```shell
git clone https://github.com/GoogleCloudPlatform/microservices-demo
cd microservices-demo
git remote add gitlab git@akha-otus.gitlab.yandexcloud.net:akha/microservices-demo.git
git remote remove origin
git push -uf gitlab main
```

 - собираем образы и размещаем их в Docker Hub
docker build -t frontend .
docker tag frontend akha/frontend:v0.0.1
docker push akha/frontend:v0.0.1


###Gitlab-CI
Подготовьте pipeline, который будет содержать следующие стадии:
 - Сборку Docker образа для каждого из микросервисов
 - Push данного образа в Docker Hub


В качестве тега образа используйте tag коммита, инициирующего
сборку (переменная CI_COMMIT_TAG в GitLab CI)

Файл .gitlab-ci.yml с пайплайном добавлен в репозиторий microservices-demo в gitlab:
https://akha-otus.gitlab.yandexcloud.net/akha/microservices-demo/


###GitOPS
####Подготовка
Ставим Flux
```shell
Ставим CLI v2.0:
curl -s https://fluxcd.io/install.sh | sudo bash

export GITLAB_TOKEN=token
export GITLAB_USER=username
flux bootstrap gitlab \
  --hostname=https://akha-otus.gitlab.yandexcloud.net \
  --owner=$GITLAB_USER \
  --repository=microservices-demo \
  --branch=main \
  --path=clusters/akha-hw-k8s \
  --token-auth \
  --components-extra=image-reflector-controller,image-automation-controller


akha@192 microservices-demo]$ flux get all
NAME                            REVISION                SUSPENDED       READY   MESSAGE
gitrepository/flux-system       main@sha1:910870fd      False           True    stored artifact for revision 'main@sha1:910870fd'

NAME                            REVISION                SUSPENDED       READY   MESSAGE
kustomization/flux-system       main@sha1:910870fd      False           True    Applied revision: main@sha1:910870fd
```

Добавляем в каталог clusters/akha-hw-k8s/deploy/namespaces файл main.yaml с манифестом для namespace microservices-demo и пушим в гитлаб:
```shell
[akha@192 namespaces]$ touch microservices-demo.yaml
[akha@192 namespaces]$ git add .
[akha@192 namespaces]$ git commit -m "ns manifest"
[akha@192 akha-hw-k8s]$ git push -uf gitlab main
```

Проверяем, что создался ns:
[akha@192 ~]$ kubectl get ns
```shell
NAME                 STATUS   AGE
default              Active   24d
flux                 Active   171m
kube-node-lease      Active   24d
kube-public          Active   24d
kube-system          Active   24d
microservices-demo   Active   9m12s
yandex-system        Active   24d
```

####Helm realese
Готовим создание сервиса frontend:
Создаем файл ./clusters/akha-hw-k8s/deploy/releases/frontend.yaml 

готвоим манифест с описанием сущностей GitRepository и ImageUpdateAutomation для FLUX2 и применяем его:
[akha@192 ~]$ kubectl apply -f flux-git-repo.yaml

Ставим istio и ServiceMonitor для приложения frontend.

```shell
[akha@192 microservices-demo]$ curl -L https://istio.io/downloadIstio | sh -
[akha@192 microservices-demo]$ cd istio-1.20.0/bin/
[akha@192 microservices-demo]$ sudo cp istioctl /usr/local/bin/
[akha@192 microservices-demo]$ istioctl manifest apply --set profile=demo
[akha@192 microservices-demo]$ kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/prometheus.yaml
```
Пушим в гитлаб наш YAML с helmRelease для frontend:

```shell
[akha@192 ~]$ git add .
[akha@192 ~]$ git commit -m "helm release"
[akha@192 ~]$ git push -uf gitlab master
[akha@192 ~]$ flux logs
2023-12-09T19:19:26.055Z info HelmChart/microservices-demo-frontend.flux-system - packaged 'frontend' chart with version '0.21.0'

```
Проверяем результат создания релиза.

```shell
[akha@192 releases]$ flux get helmrelease -n microservices-demo
NAME            REVISION        SUSPENDED       READY   MESSAGE
frontend        0.21.0          False           True    Release reconciliation succeeded


[akha@192 bin]$ kubectl get po -n microservices-demo
NAME                        READY   STATUS    RESTARTS   AGE
frontend-747889845c-gbqqb   1/1     Running   0          62s
    Image:          akha/frontend:v0.0.1

```

####
Готовим файл с описанием сущностей imagerepository и imagepolicy и применяем его:
[akha@192 kubernetes-gitops]$ kubectl apply -f flux-frontend.yaml

пересобираем образ с версией 0.0.2
```shell
docker build -t frontend .
docker tag frontend akha/frontend:v0.0.2
docker push akha/frontend:v0.0.2
[akha@192 ~]$ flux get  image policy frontend -n flux-system
NAME            LATEST IMAGE            READY   MESSAGE
frontend        akha/frontend:v0.0.2    True    Latest image tag for 'akha/frontend' resolved to v0.0.2
```
Повысим версию до 0.0.3 и принудительно запросим изменения:
```shell
[akha@192 ~]$ flux reconcile image update flux-system
[akha@192 ~]$ flux get  image policy frontend -n flux-system
NAME            LATEST IMAGE            READY   MESSAGE
frontend        akha/frontend:v0.0.3    True    Latest image tag for 'akha/frontend' updated from v0.0.2 to v0.0.3
```
В гитлабе также видим изменение версии в манифесте:
```
Last commit: akha/frontend:v0.0.3

-      tag: v0.0.2 # {"$imagepolicy": "flux-system:frontend:tag"}
+      tag: v0.0.3 # {"$imagepolicy": "flux-system:frontend:tag"}
```

Создаем для каждого микросервиса свой CR HelmRelease и кладем их в каталог /clusters/production/releases, ждем синхронизацию, видим, что микросервисы развернулись автоматически.
```shell
[akha@192 ~]$ kubectl get helmreleases   -n microservices-demo -o wide
NAME                    AGE    READY   STATUS
adservice               65s    True    Release reconciliation succeeded
cartservice             32m    True    Release reconciliation succeeded
checkoutservice         29m    True    Release reconciliation succeeded
currencyservice         29m    True    Release reconciliation succeeded
emailservice            26m    True    Release reconciliation succeeded
frontend                2d3h   True    Release reconciliation succeeded
loadgenerator           24m    True    Release reconciliation succeeded
paymentservice          26m    True    Release reconciliation succeeded
productcatalogservice   26m    True    Release reconciliation succeeded
recommendationservice   26m    True    Release reconciliation succeeded
shippingservice         26m    True    Release reconciliation succeeded
```


### CD

#### ISTIO

Установка:
```shell
[akha@192 microservices-demo]$ curl -L https://istio.io/downloadIstio | sh -
[akha@192 microservices-demo]$ cd istio-1.20.0/bin/
[akha@192 microservices-demo]$ sudo cp istioctl /usr/local/bin/
[akha@192 microservices-demo]$ istioctl manifest apply --set profile=demo
[akha@192 microservices-demo]$ kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/prometheus.yaml

```

#### FLAGGER
Установка Flagger
```shell

helm repo add flagger https://flagger.app
kubectl apply -f https://raw.githubusercontent.com/weaveworks/flagger/master/artifacts/flagger/crd.yaml
helm upgrade --install flagger flagger/flagger --namespace=istio-system --set crd.create=false --set meshProvider=istio --set metricsServer=http://prometheus.monitoring.svc.cluster.local:9090
```

####istio sidecar injector
Добавить в  манифест для namespace

    labels:
      istio-injection: enabled   
      
Запушим в репо и проверим результат:
```shell
[akha@192 namespaces]$ kubectl get ns microservices-demo --show-labels
NAME                 STATUS   AGE   LABELS
microservices-demo   Active   10d   istio-injection=enabled,kubernetes.io/metadata.name=microservices-demo,kustomize.toolkit.fluxcd.io/name=flux-system,kustomize.toolkit.fluxcd.io/namespace=flux-system
```
Пересоздадим поды
[akha@192 namespaces]$ kubectl delete pods --all -n microservices-demo

Проверим:
```shell
[akha@192 namespaces]$ kubectl describe pod -l app=frontend -n microservices-demo
Containers:
  server:
    Container ID:   docker://18f462ffbdf566af1370338b1f1a002afdc6f34e138ddc8f1d711b8d8cda2bc6
    Image:          akha/frontend:v0.0.3
...

  istio-proxy:
    Container ID:  docker://01e020a5a49facaa0db0ec761e4c79a28c2fd3993ada501183b44ca695208b23
    Image:         docker.io/istio/proxyv2:1.20.0
...
```
Применяем манифесты для VirtualService и Gateway,получаем результат:

```
[akha@192 istio]$ kubectl get gateway -n microservices-demo
NAME               AGE
frontend           76s

[akha@192 istio]$ kubectl get virtualservice -n microservices-demo
NAME       GATEWAYS       HOSTS   AGE
frontend   ["frontend"]   ["*"]   7d23h

[akha@192 istio]$ kubectl get svc istio-ingressgateway -n istio-system
NAME                   TYPE           CLUSTER-IP       EXTERNAL-IP      PORT(S)                                                                      AGE
istio-ingressgateway   LoadBalancer   172.16.251.225   158.160.132.27   15021:30420/TCP,80:31037/TCP,443:31544/TCP,31400:30414/TCP,15443:31276/TCP   7d23h
```


Переходим в бразуере по EXTERNAL-IP и видим, что frontend отвечает.
```
This website is hosted for demo purposes only. It is not an actual shop. This is not a Google product.
```

 - Istio | Самостоятельное задание
Переносим ресурсы istio frontend-vs.yaml, frontend-gw.yaml в /deploy/charts/frontend а т.к. они логически являются частью окружение микросервиса frontend
gateway.yaml
virtualService.yaml

###CANARY

Готовим манифест canary.yml, применяем манифест и проверяем:
```shell
[akha@192 templates]$ kubectl get canary -n microservices-demo
NAME       STATUS         WEIGHT   LASTTRANSITIONTIME
frontend   Initializing   0        2023-12-17T19:44:31Z

[akha@192 templates]$ kubectl get pods -n microservices-demo -l app=frontend-primary
NAME                                READY   STATUS    RESTARTS   AGE
frontend-primary-6b4fbdd6bd-gvvqj   2/2     Running   0          40s
```
Пересобираем образ:

docker build -t frontend .
docker tag frontend akha/frontend:v0.0.4
docker push akha/frontend:v0.0.4

Получаем ошибку:
```shell
  Warning  Synced  14s                flagger  Rolling back frontend.microservices-demo failed checks threshold reached 1
  Warning  Synced  14s                flagger  Canary failed! Scaling down frontend.microservices-demo
```
Доставляем прометеус и правим хост в load-generator:
```shell
[akha@192 microservices-demo]$ kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/prometheus.yaml
[akha@192 microservices-demo]$helm upgrade --install flagger flagger/flagger --namespace=istio-system --set crd.create=false --set meshProvider=istio --set metricsServer=http://prometheus:9090

```

После правки хоста в чарте load-generator, корректировки canary.yaml и установки promethteus для istio все заработало.

```shell
  Normal   Synced  3m52s (x3 over 19m)    flagger  New revision detected! Scaling up frontend.microservices-demo
  Normal   Synced  3m22s (x3 over 14m)    flagger  Starting canary analysis for frontend.microservices-demo
  Normal   Synced  3m22s (x3 over 14m)    flagger  Advance frontend.microservices-demo canary weight 10
  Normal   Synced  2m52s (x2 over 7m52s)  flagger  Advance frontend.microservices-demo canary weight 20
  Normal   Synced  2m22s (x2 over 7m22s)  flagger  Advance frontend.microservices-demo canary weight 30
  Normal   Synced  112s (x2 over 6m52s)   flagger  Advance frontend.microservices-demo canary weight 40
  Normal   Synced  82s (x2 over 6m22s)    flagger  Advance frontend.microservices-demo canary weight 50
  Normal   Synced  52s                    flagger  Copying frontend.microservices-demo template spec to frontend-primary.microservices-demo
  Normal   Synced  22s                    flagger  Routing all traffic to primary
  Normal   Synced  4m51s                flagger  (combined from similar events): Promotion completed! Scaling down frontend.microservices-demo


```

## PR checklist:
 - [*] Выставлен label с темой домашнего задания
