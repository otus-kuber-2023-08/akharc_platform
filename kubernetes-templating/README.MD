/--------------------------------------------------------------
# akharc_platform
akharc Platform repository
# Выполнено ДЗ №6

 - [ ] Основное ДЗ
 - [ ] Задание со * chartmuseum
 - [ ] Задание со * готовим файл helmfile.yaml
 - [ ] Задание со * Создаем свой helm chart REDIS
 - [ ] Задание со * JSONNET

## В процессе сделано:
- Натроено подключение и работа с YC
- Поставили nginx-ingress,cert-manager, chartmuseum, harbor при помощи helm-чартов, начуились готовить values
- Поставили hipster-shopс помощью собственного чарта

## Как проверить работоспособность:
 - Prereq: настраиваем утилиту YC:
по инструкции https://cloud.yandex.ru/docs/cli/quickstart#install
```shell
curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
yc init

yc managed-kubernetes cluster get-credentials otus-akha --external
```
#### HELM
Устанавливаем HELM
```shell
[akha@192 ~]$ wget https://get.helm.sh/helm-v3.12.2-linux-amd64.tar.gz
tar -zxvf helm-v3.12.2-linux-amd64.tar.gz
[akha@192 linux-amd64]$ sudo mv helm /usr/local/bin/helm
[akha@192 linux-amd64]$ helm version
version.BuildInfo{Version:"v3.12.2", GitCommit:"1e210a2c8cc5117d1055bfaa5d40f51bbc2e345e", GitTreeState:"clean", GoVersion:"go1.20.5"}

[akha@192 linux-amd64]$ helm repo add stable https://charts.helm.sh/stable
"stable" has been added to your repositories
```

 -  ставим nginx-ingress
```shell
kubectl create ns nginx-ingress


helm upgrade --install nginx-ingress ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx/\
  --namespace nginx-ingress  --atomic


[akha@192 kubernetes-controllers]$ kubectl get po --namespace nginx-ingress
NAME                                                      READY   STATUS    RESTARTS   AGE
nginx-ingress-ingress-nginx-controller-794cf98964-9npc5   1/1     Running   0          68s


[akha@192 kubernetes-controllers]$ kubectl get svc --namespace nginx-ingress
NAME                                               TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)                      AGE
nginx-ingress-ingress-nginx-controller             LoadBalancer   172.20.228.209   158.160.58.88   80:30098/TCP,443:32140/TCP   102s
nginx-ingress-ingress-nginx-controller-admission   ClusterIP      172.20.220.92    <none>          443/TCP                      102s




```
 - Ставим cert-manager
Nota bene: нужно убедиться, что на рабочей машине в хранилище сертов есть нужные корневые и промежуточные. Использовать для работы будем Staging LetsEncrypt, т.к. для prod домена nip.io очень много желающиюх, что не укладывается в RateLimit:
yum install ca-certificates
update-ca-trust force-enable
далее копируем корневые и промежуточные в /etc/pki/ca-trust/source/anchors/
update-ca-trust extract 

```shell
helm repo add jetstack https://charts.jetstack.io
helm repo update
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.12.0/cert-manager.crds.yaml

kubectl get pods -n cert-manager --watch


helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.12.0 \
  
 
[akha@192 .ssh]$ kubectl get po  --namespace cert-manager
NAME                                       READY   STATUS    RESTARTS   AGE
cert-manager-576c79cb45-52sqr              1/1     Running   0          34s
cert-manager-cainjector-664f76bc59-nrhgz   1/1     Running   0          34s
cert-manager-webhook-5d4fd5cb7f-df8rn      1/1     Running   0          34s

[akha@192 cert-manager]$ kubectl apply -f issuer.yaml
issuer.cert-manager.io/letsencrypt-staging created
issuer.cert-manager.io/letsencrypt-prod created
certificate.cert-manager.io/nginx-cert created

  
```
 - установка chartmuseum
```shell
[akha@192 chartmuseum]$ kubectl create ns chartmuseum

[akha@192 chartmuseum]$ helm repo add chartmuseum https://chartmuseum.github.io/charts 
[akha@192 chartmuseum]$ helm repo update
[akha@192 chartmuseum]$ helm upgrade --install chartmuseum chartmuseum/chartmuseum --wait \
--namespace=chartmuseum \
--version=3.10.0 -f values.yaml

NAME: chartmuseum
LAST DEPLOYED: Thu Jul 27 20:57:05 2023
NAMESPACE: chartmuseum
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
** Please be patient while the chart is being deployed **

Get the ChartMuseum URL by running:

  export POD_NAME=$(kubectl get pods --namespace chartmuseum -l "app=chartmuseum" -l "release=chartmuseum" -o jsonpath="{.items[0].metadata.name}")
  echo http://127.0.0.1:8080/
  kubectl port-forward $POD_NAME 8080:8080 --namespace chartmuseum
  
 [akha@192 chartmuseum]$ helm ls -n chartmuseum
NAME            NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                   APP VERSION
chartmuseum     chartmuseum     1               2023-07-27 20:57:05.365144706 +0300 MSK deployed        chartmuseum-3.10.0      0.16.0

[akha@192 chartmuseum]$ kubectl get secrets -n chartmuseum
NAME                                TYPE                 DATA   AGE
158.160.58.88.nip.io.secret-27qh7   Opaque               1      2m17s
chartmuseum                         Opaque               0      2m18s
sh.helm.release.v1.chartmuseum.v1   helm.sh/release.v1   1      2m18s


```
Установка Harbor
```shell

[akha@192 harbor]$ kubectl create ns harbor

[akha@192 harbor]$helm repo add harbor https://helm.goharbor.io 
[akha@192 harbor]$ helm repo update

helm upgrade --install harbor harbor/harbor --wait \
--namespace=harbor \
--version=1.12.2 \
-f values.yaml

helm upgrade delete harbor harbor/harbor --namespace=harbor
[akha@192 harbor]$ kubectl get secrets -n harbor -l owner=helm
NAME                           TYPE                 DATA   AGE
sh.helm.release.v1.harbor.v1   helm.sh/release.v1   1      9m41s

```
С выпуском сертификата были проблемы:
Error creating new order :: too many certificates already issued for "nip.io".
Пришлось использовать staging issuer


 - Задание со * - готовим файл helmfile.yaml
файл с описанием репозиториев и релизов лежит в каталоге kubernetes-templating/helmfile/
 - Готовим свой HelmChart
```shell
[akha@192 akharc_platform]$ helm create kubernetes-templating/hipster-shop
[akha@192 akharc_platform]$ helm create kubernetes-templating/frontend
[akha@192 chartmuseum]$ kubectl create ns hipster-shop
helm upgrade --install hipster-shop kubernetes-templating/hipster-shop --namespace hipster-shop
helm upgrade --install frontend kubernetes-templating/frontend --namespace hipster-shop

```
#### Пришло время минимально шаблонизировать наш chart frontend
 - выносим данные в переменные (смотри файл values.yaml)
Добавляем значения в файл values.yaml
Добавляем ссылки на заданные параметры в манифестах deployment и serviece для frontend
Удаляем релиз frontend из кластера и добавляем его в зависимости в Chart.yaml
```shell
[akha@192 frontend]$ helm delete frontend -n hipster-shop
release "frontend" uninstalled
helm dep update kubernetes-templating/hipster-shop
helm upgrade hipster-shop kubernetes-templating/hipster-shop --namespace hipster-shop

helm upgrade --install hipster-shop kubernetes-templating/hipster-shop --namespace hipster-shop --set frontend.service.NodePort=31234


```
 - добавляем чарты в Harbor
```shell
helm package kubernetes-templating/hipster-shop/
helm package kubernetes-templating/frontend/

helm registry login -u admin https://harbor.158.160.58.88.nip.io

[akha@192 akharc_platform]$ helm push hipster-shop-0.1.0.tgz oci://harbor.158.160.58.88.nip.io/hipster-shop
Pushed: harbor.158.160.58.88.nip.io/hipster-shop/hipster-shop:0.1.0
Digest: sha256:6d3fbb74a661a51858975722ee9ccb75b7431fef3aa61517013a2240369800f6
[akha@192 akharc_platform]$ helm push frontend-0.1.0.tgz oci://harbor.158.160.58.88.nip.io/hipster-shop
Pushed: harbor.158.160.58.88.nip.io/hipster-shop/frontend:0.1.0
Digest: sha256:dca8eac5d1c884cc693936cf207dc5e7877d4c535071347e762291dc1bb1ae67

```
#### Kubecfg/jsonnet

Савим:

```shell
wget https://github.com/vmware-archive/kubecfg/releases/download/v0.22.0/kubecfg-linux-amd64
sudo chmod +x kubecfg
sudo cp kubecfg-linux-amd64 /usr/local/bin/kubecfg
kubecfg version
kubecfg version: v0.22.0
jsonnet version: v0.17.0
client-go version: v0.0.0-master+$Format:%h

kubecfg update services.jsonnet --namespace hipster-shop
```
правим services.jsonnet, проверяем и запускаем:
```shell
```
####Kustomize
Kustomize – это инструмент, позволяющий пользователям «настраивать простые и свободные от шаблонов файлы YAML под различные цели, оставляя оригинальный YAML нетронутым и пригодным для использования»
https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/
выбираем для кастомиизации 1-й мигросервис - adservice и передеплоим:


```shell
helm upgrade hipster-shop kubernetes-templating/hipster-shop --namespace hipster-shop
```
В каталоге /kustomization/base находятся базовые манифесты и файл kustomize указывающих какие ресурсы нужно кастомизировать. В  overrides описаны окружения Dev и Prod.
```shell
[akha@192 akharc_platform]$ kubectl apply -k kubernetes-templating/kustomize/overrides/dev/
service/dev-adservice created
deployment.apps/dev-adservice created

[akha@192 akharc_platform]$ kubectl apply -k kubernetes-templating/kustomize/overrides/prod/
namespace/hipster-shop-prod created
service/prod-adservice created
deployment.apps/prod-adservice created


[akha@192 akharc_platform]$ kubectl get po -n hipster-shop-prod
NAME                              READY   STATUS    RESTARTS   AGE
prod-adservice-769cf55fd6-msphr   1/1     Running   0          44s

[akha@192 akharc_platform]$ kubectl get svc -n hipster-shop-prod
NAME             TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
prod-adservice   ClusterIP   172.20.167.106   <none>        9555/TCP   62s

```

## PR checklist:
 - [*] Выставлен label с темой домашнего задания
 
