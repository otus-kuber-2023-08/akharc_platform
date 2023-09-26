# akharc_platform
akharc Platform repository
# Выполнено ДЗ №5

 - [ ] Основное ДЗ
 - [ ] Задание со *

## В процессе сделано:
- Созданы namspace
- Созданы ServiceAccount в рамках namespace
- Созданы Роли в рамках namespace и ClusterRoleв рамках кластера, выполнена их привязка к сервис-аккаунтам

## Как проверить работоспособность:
task01 Создать Service Account bob, дать ему роль admin в рамках всего кластера
Создать Service Account dave без доступа к кластеру
 
```shell 
kubectl apply -f 01-bob-superadmin.yaml
serviceaccount/bob created
clusterrolebinding.rbac.authorization.k8s.io/bob created

kubectl describe sa bob
Name:                bob
Namespace:           default
Labels:              <none>
Annotations:         <none>
Image pull secrets:  <none>
Mountable secrets:   <none>
Tokens:              <none>
Events:              <none>


[akha@192 kubernetes-security]$ kubectl describe clusterrolebinding bob-superadm
Name:         bob-superadm
Labels:       <none>
Annotations:  <none>
Role:
  Kind:  ClusterRole
  Name:  system:cluster-admin
Subjects:
  Kind            Name  Namespace
  ----            ----  ---------
  ServiceAccount  bob   default

[akha@192 kubernetes-security]$ kubectl apply -f 02-dave.yaml
serviceaccount/dave created

kubectl describe sa dave
Name:                dave
Namespace:           default
Labels:              <none>
Annotations:         <none>
Image pull secrets:  <none>
Mountable secrets:   <none>
Tokens:              <none>
Events:              <none>
```

task02 Создать Namespace prometheus 
Создать Service Account carol в этом Namespace
Дать всем Service Account в Namespace prometheus возможность делать get, list, watch в отношении Pods всего кластера

```shell
kubectl apply -f 01-prometheus-namespace.yaml
namespace/prometheus created

kubectl apply -f 02-carol-prometheus.yaml
serviceaccount/carol created
kubectl apply -f 03-pod-reader-role-prometheus.yaml
clusterrole.rbac.authorization.k8s.io/pod-reader unchanged
clusterrolebinding.rbac.authorization.k8s.io/prometheus-role created

kubectl describe clusterrole pod-reader
Name:         pod-reader
Labels:       <none>
Annotations:  <none>
PolicyRule:
  Resources  Non-Resource URLs  Resource Names  Verbs
  ---------  -----------------  --------------  -----
  pods       []                 []              [get watch list]

```
 task03 Создать Namespace dev
 Создать Service Account jane в Namespace dev
 Дать jane роль admin в рамках Namespace dev
 Создать Service Account ken в Namespace dev
 Дать ken роль view в рамках Namespace dev

```shell
[akha@192 kubernetes-security]$ kubectl apply -f task03
namespace/dev created
serviceaccount/jane created
role.rbac.authorization.k8s.io/admin created
rolebinding.rbac.authorization.k8s.io/devadmin created
serviceaccount/ken created
role.rbac.authorization.k8s.io/view created
rolebinding.rbac.authorization.k8s.io/dev-view created

 kubectl  -n dev describe sa jane
Name:                jane
Namespace:           dev
Labels:              <none>
Annotations:         <none>
Image pull secrets:  <none>
Mountable secrets:   <none>
Tokens:              <none>
Events:              <none>

kubectl  -n dev describe sa ken
Name:                ken
Namespace:           dev
Labels:              <none>
Annotations:         <none>
Image pull secrets:  <none>
Mountable secrets:   <none>
Tokens:              <none>
Events:              <none>

kubectl  -n dev describe role admin
Name:         admin
Labels:       <none>
Annotations:  <none>
PolicyRule:
  Resources  Non-Resource URLs  Resource Names  Verbs
  ---------  -----------------  --------------  -----
  *.*        []                 []              [*]

 kubectl  -n dev describe role view
Name:         view
Labels:       <none>
Annotations:  <none>
PolicyRule:
  Resources  Non-Resource URLs  Resource Names  Verbs
  ---------  -----------------  --------------  -----
  *.*        []                 []              [get list watch]

```

## PR checklist:
 - [*] Выставлен label с темой домашнего задания
