# akharc_platform
akharc Platform repository
# Выполнено ДЗ №4

 - [ ] Основное ДЗ
 - [ ] Задание со *

## В процессе сделано:
- Создан StatefulSet minio с PVC и PV
- Создан HeadlessService
- Со * СозданыSecret для логина/пароля, скорректирован и переприменен  StatefulSet minio

## Как проверить работоспособность:
task01 StatefulSet minio с PVC и PV, HeadlessService

```shell
kubectl apply -f minio-statefulset.yaml
kubectl apply -f minio-headlessservice.yaml

[akha@192 kubernetes-volumes]$ kubectl get statefulsets
NAME    READY   AGE
minio   1/1     3m57s

[akha@192 kubernetes-volumes]$ kubectl get pods
NAME      READY   STATUS    RESTARTS   AGE
minio-0   1/1     Running   0          4m40s
[akha@192 kubernetes-volumes]$ ^C

[akha@192 kubernetes-volumes]$ kubectl get pvc
NAME           STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
data-minio-0   Bound    pvc-693000cc-fdcf-4688-a7c3-2e139b320075   10Gi       RWO            standard       5m48s

[akha@192 kubernetes-volumes]$ kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                  STORAGECLASS   REASON   AGE
pvc-693000cc-fdcf-4688-a7c3-2e139b320075   10Gi       RWO            Delete           Bound    default/data-minio-0   standard                6m55s
```

task02 Со * Поместите данные в  и настройте конфигурацию на их использование.
  Шифруем креды:
```shell
echo -n 'minio' | base64
bWluaW8=
echo -n 'minio123' | base64
bWluaW8xMjM=
```
Готовим и применяме манифест для секретов:
```shell
apiVersion: v1
kind: Secret
metadata:
  name: minio
  labels:
    app: minio
type: Opaque
data:
  username: bWluaW8=
  password: bWluaW8xMjM=


kubectl apply -f secret.yaml
```

  Корректируем StatefulSet, применяем, проверяем:
```shell
---
      containers:
      - name: minio
        env:
        - name: MINIO_SECRET_USERNAME
          valueFrom:
            secretKeyRef:
              name: minio
              key: username
        - name: MINIO_SECRET_PASSWORD
          valueFrom:
            secretKeyRef:
              name: minio
              key: password
---
kubectl apply -f minio-statefulset.yaml

kubectl exec -i -t minio-0  -- /bin/sh -c 'echo $MINIO_SECRET_USERNAME'
minio
kubectl exec -i -t minio-0  -- /bin/sh -c 'echo $MINIO_SECRET_PASSWORD'
minio123
```

## PR checklist:
 - [*] Выставлен label с темой домашнего задания
