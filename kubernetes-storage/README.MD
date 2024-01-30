# akharc_platform
akharc Platform repository
# Выполнено ДЗ №11

 - [ ] Основное ДЗ
 - [ ] Задание со * 


## В процессе сделано:
- Установлен CSI-драйвер, проверен функционал снэпшотов



## Как проверить работоспособность:
###Подготовка к работе
Запущен кластер k8s в Yandex Cloud
###StorageClass для CSI Host Path Driver
 - Устанавливаем External Snapshotter и CSI HostPath Driver:

``` shell
$ git clone https://github.com/kubernetes-csi/external-snapshotter.git
$ kubectl kustomize client/config/crd | kubectl create -f -
$ kubectl -n kube-system kustomize deploy/kubernetes/snapshot-controller | kubectl create -f -
$ kubectl -n kube-system kustomize deploy/kubernetes/csi-snapshotter| kubectl create -f -
$ deploy/kubernetes-latest/deploy.sh
```

 - Создаем StorageClass
``` shell
[akha@192 kubernetes-storage]$ kubectl apply -f storageclass.yaml
storageclass.storage.k8s.io/csi-hostpath-sc created


[akha@192 kubernetes-storage]$ kubectl get storageclasses.storage.k8s.io
NAME                           PROVISIONER                     RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
csi-hostpath-sc                hostpath.csi.k8s.io             Delete          Immediate              true                   46m
yc-network-hdd (default)       disk-csi-driver.mks.ycloud.io   Delete          WaitForFirstConsumer   true                   106d
yc-network-nvme                disk-csi-driver.mks.ycloud.io   Delete          WaitForFirstConsumer   true                   106d
yc-network-ssd                 disk-csi-driver.mks.ycloud.io   Delete          WaitForFirstConsumer   true                   106d
yc-network-ssd-io-m3           disk-csi-driver.mks.ycloud.io   Delete          WaitForFirstConsumer   true                   56d
yc-network-ssd-nonreplicated   disk-csi-driver.mks.ycloud.io   Delete          WaitForFirstConsumer   true                   106d
```
 - PVC
``` shell
[akha@192 kubernetes-storage]$ kubectl apply -f  pvc.yaml
persistentvolumeclaim/storage-pvc created
[akha@192 kubernetes-storage]$ kubectl get pvc
NAME                                  STATUS    VOLUME                                     	CAPACITY   ACCESS MODES   STORAGECLASS      	AGE
storage-pvc		              Bound     pvc-69c3a67f-4716-4447-84ac-ef90bbc92e2e 	  1Gi        RWO  	  csi-hostpath-sc   	13m
```
 - Создаем под
```shell
$ k apply -f ./kubernetes-storage/pod.yaml 
pod/storage-pod created
```

## PR checklist:
 - [*] Выставлен label с темой домашнего задания