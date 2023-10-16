/--------------------------------------------------------------
# akharc_platform
akharc Platform repository
# Выполнено ДЗ №7

 - [ ] Основное ДЗ
 - [ ] Задание со *

## В процессе сделано:
- Созданы CustomResource и CustomResourceDefinition для mysql оператора.
- Подготовлен скрипт для запуска оператора
- подготовлен образ оператора и проверена работа джобов бэкапа и восстановления


## Как проверить работоспособность:
 - Создаем CR и CRD
для CRD нужно использовать формат манифеста v1, описанный по ссылке:
https://redhat-connect.gitbook.io/certified-operator-guide/ocp-deployment/operator-metadata/update-crds-from-v1beta1
https://habr.com/ru/companies/otus/articles/669806/
и удалить usless_data: "useless info из cr.yml

```shell
[akha@192 deploy]$ kubectl apply -f crd.yml
customresourcedefinition.apiextensions.k8s.io/mysqls.otus.homework created
[akha@192 deploy]$ kubectl apply -f cr.yml
mysql.otus.homework/mysql-instance created

[akha@192 deploy]$ kubectl get crd
NAME                   CREATED AT
mysqls.otus.homework   2023-07-13T17:49:10Z

[akha@192 deploy]$ kubectl describe mysqls.otus.homework mysql-instance
Name:         mysql-instance
Namespace:    default
Labels:       <none>
Annotations:  <none>
API Version:  otus.homework/v1
Kind:         MySQL
Metadata:
  Creation Timestamp:  2023-07-13T17:51:22Z
  Generation:          1
  Resource Version:    1941
  UID:                 a0b27f01-2be2-4129-a1df-c842dda81718
Spec:
  Database:      otus-database
  Image:         mysql:5.7
  Password:      otuspassword
  storage_size:  1Gi
Events:          <none>

```

 -  готовим python скрипт для контроллера оператора
готовим скрипт и ставим пререквизиты: 
```shell
[akha@192 web]$ pip install jinja
[akha@192 web]$ pip install kubernetes
[akha@192 web]$ pip install kopf
[akha@192 web]$kopf run mysql-operator.py
[2023-07-15 20:54:03,340] kopf.objects         [INFO    ] [default/mysql-instance] Handler 'mysql_on_create' succeeded.
[2023-07-15 20:54:03,340] kopf.objects         [INFO    ] [default/mysql-instance] Creation is processed: 1 succeeded; 0 failed.

[akha@192 build]$ kubectl get po
NAME                              READY   STATUS    RESTARTS   AGE
mysql-instance-6854d75fc7-wfn7p   1/1     Running   0          12m

kubectl apply -f cr.yml
mysql.otus.homework/mysql-instance created

[akha@192 deploy]$ kubectl get pvc
NAME                        STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
backup-mysql-instance-pvc   Bound    pvc-1021d5a4-a88d-4e40-849c-0df646c578f7   1Gi        RWO            standard       4s
mysql-instance-pvc          Bound    pvc-8deda2b8-560a-4378-95ba-9ae3dabe2a68   1Gi        RWO            standard       4s

проверяем:
[akha@192 build]$ kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "select * from test;" otus-database

+----+-------------+
| id | name        |
+----+-------------+
|  1 | some data   |
|  2 | some data-2 |
|  3 | some data-2 |

```
удаляем инстанс и проверяем restore


```shell
kubectl delete mysqls.otus.homework mysql-instance

[akha@192 deploy]$ kubectl delete svc mysql-instance
service "mysql-instance" deleted
[akha@192 deploy]$ export MYSQLPOD=$(kubectl get pods -l app=mysql-instance -o jsonpath="{.items[*].metadata.name}")
[akha@192 deploy]$ kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "select * from test;" otus-database
mysql: [Warning] Using a password on the command line interface can be insecure.
+----+-------------+
| id | name        |
+----+-------------+
|  1 | some data-2 |
|  2 | some data-2 |
+----+-------------+

```
 - собираем образ и проверяем работу
```shell
docker build -t k8s-mysql-operator .
docker tag k8s-mysql-operator akha/k8s-mysql-operator:latest
docker push akha/k8s-mysql-operator:latest

```
Проверим, что все работает
```shell

[akha@192 deploy]$ kubectl apply -f service-account.yml
serviceaccount/mysql-operator created
[akha@192 deploy]$ kubectl apply -f role.yml
clusterrole.rbac.authorization.k8s.io/mysql-operator created
[akha@192 deploy]$ kubectl apply -f role-binding.yml
clusterrolebinding.rbac.authorization.k8s.io/workshop-operator created
[akha@192 deploy]$ kubectl apply -f deploy-operator.yml
deployment.apps/mysql-operator created
[akha@192 deploy]$ kubectl apply -f cr.yml
mysql.otus.homework/mysql-instance created


[akha@192 ~]$ kubectl get pvc
NAME                        STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
backup-mysql-instance-pvc   Bound    pvc-5aebc2a0-6242-48f7-85d5-19b661a47589   1Gi        RWO            standard       7s
mysql-instance-pvc          Bound    pvc-2f9d52a4-ad6b-45f2-ae37-a8f2308453e8   1Gi        RWO            standard       8s
```
результат заполнения БД:
```shell
[akha@192 deploy]$ export MYSQLPOD=$(kubectl get pods -l app=mysql-instance -o jsonpath="{.items[*].metadata.name}")
[akha@192 deploy]$ kubectl exec -it $MYSQLPOD -- mysql -u root -potuspassword -e "CREATE TABLE test ( id smallint unsigned not null auto_increment, name varchar(20) not null, constraint pk_example primary key (id) );" otus-database
mysql: [Warning] Using a password on the command line interface can be insecure.
[akha@192 deploy]$ kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "INSERT INTO test ( id, name ) VALUES ( null, 'some data-1' );" otus-database
mysql: [Warning] Using a password on the command line interface can be insecure.
[akha@192 deploy]$ kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "INSERT INTO test ( id, name ) VALUES ( null, 'some data-2' );" otus-database
mysql: [Warning] Using a password on the command line interface can be insecure.
[akha@192 deploy]$ kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "select * from test;" otus-database
mysql: [Warning] Using a password on the command line interface can be insecure.
+----+-------------+
| id | name        |
+----+-------------+
|  1 | some data-1 |
|  2 | some data-2 |
+----+-------------+
```

 - Удаляем инстанс:
```shell
kubectl delete mysqls.otus.homework mysql-instance
mysql.otus.homework "mysql-instance" deleted

[akha@192 deploy]$ kubectl get jobs.batch
NAME                        COMPLETIONS   DURATION   AGE
backup-mysql-instance-job   1/1           4s         53s

```

 - Создадим заново mysql-instance и проверим работу:

```shell
[akha@192 deploy]$ kubectl apply -f cr.yml
mysql.otus.homework/mysql-instance created

[akha@192 deploy]$ export MYSQLPOD=$(kubectl get pods -l app=mysql-instance -o jsonpath="{.items[*].metadata.name}")
[akha@192 deploy]$ kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "select * from test;" otus-database
mysql: [Warning] Using a password on the command line interface can be insecure.
+----+-------------+
| id | name        |
+----+-------------+
|  1 | some data-1 |
|  2 | some data-2 |
+----+-------------+

[akha@192 templates]$ kubectl get jobs
NAME                         COMPLETIONS   DURATION   AGE
backup-mysql-instance-job    1/1           4s         4m53s
restore-mysql-instance-job   1/1           49s        3m18s

```

## PR checklist:
 - [*] Выставлен label с темой домашнего задания
 
 