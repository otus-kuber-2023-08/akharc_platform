/--------------------------------------------------------------
# akharc_platform
akharc Platform repository
# Выполнено ДЗ №14

 - [ ] Основное ДЗ
 - [ ] Задание со * 


## В процессе сделано:
 - развернут кластер версии 1.23 и затем обновлен
 - развернут кластер через kubespray



## Как проверить работоспособность:

### Готовим инфраструктуру:

- Настраиваем терраформ на работу с ЯОблаком
``` shell
yc iam key create \
  --service-account-id <идентификатор_сервисного_аккаунта> \
  --folder-name <имя_каталога_с_сервисным_аккаунтом> \
  --output key.json

id: *значение*
service_account_id: *значение*
created_at: "2024-02-24T12:22:14.241173512Z"
key_algorithm: RSA_2048

[akha@192 ~]$ yc config profile create akha-k8s-tf
Profile 'akha-k8s-tf' created and activated

yc config set service-account-key key.json
yc config set cloud-id *значение*
yc config set folder-id *значение*

export YC_TOKEN=$(yc iam create-token)
export YC_CLOUD_ID=$(yc config get cloud-id)
export YC_FOLDER_ID=$(yc config get folder-id)
```

- выбираем образ    
``` shell
yc compute image list --folder-id standard-images  | grep ubuntu-20-04

export PATH=$PATH:/usr/local/src

| fd85an6q1o26nf37i2nl | ubuntu-20-04-lts-v20231218                                 | ubuntu-2004-lts                                 | f2ekp29fd7vk7pke4hj5           | READY  |
```
 - далее ставим Terraform из зеркала Яндекса, делаем terraform init и разворачиваем ноды
``` shell
[akha@192 tf]$ terraform init

[akha@192 tf]$ terraform plan
[akha@192 tf]$ terraform apply --auto-approve

master_hostname = "master"
master_private_ip = "192.168.1.100"
master_public_ip = "XXXX"
worker_nodes_hostnames = [
  "worker-1",
  "worker-2",
  "worker-3",
]
worker_nodes_private_ips = [
  "192.168.1.201",
  "192.168.1.202",
  "192.168.1.203",
]
``` 

 - Настраиваем подключение по ssh к мастер-ноде и к воркерам, мастер выступает в роли jump-хоста
добавляем в ~/.ssh/config параметры подключения к мастеру и заходим на него
``` shell
echo 'ip-addr master kubernetes' | sudo tee -a /etc/hosts
ssh master
``` 
на мастере добавляем в ~/.ssh/config параметры подключения к воркерам, подкидывваем ssh-ключ и правим /etc/hosts
``` shell
# Your system has configured 'manage_etc_hosts' as True.
# As a result, if you wish for changes to this file to persist
# then you will need to either
# a.) make changes to the master file in /etc/cloud/templates/hosts.debian.tmpl
# b.) change or remove the value of 'manage_etc_hosts' in
#     /etc/cloud/cloud.cfg or cloud-config from user-data
#
127.0.1.1 master.ru-central1.internal master
127.0.0.1 localhost

# The following lines are desirable for IPv6 capable hosts
::1 localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
192.168.1.100 master
192.168.1.201 worker-1
192.168.1.202 worker-2
192.168.1.203 worker-3
```

далее актуализируем /etc/hosts на воркерах

### Подготовка машин

####Отключаем свап
```shell
ubuntu@master:~$ sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
ubuntu@master:~$ sudo swapoff -a
```
#### Загрузим br_netfilter и позволим iptables видеть трафик.

на всех машинах:
```shell
$ cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

$ sudo modprobe overlay
$ sudo modprobe br_netfilter

$ cat <<EOF | sudo tee /etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-iptables=1 
net.ipv4.ip_forward=1 
net.bridge.bridge-nf-call-ip6tables=1 
EOF

$ sudo sysctl --system
```
#### Установим Containerd
на всех машинах:
```shell
$ curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
$ sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
$ sudo apt update -y
$ sudo apt install -y containerd.io
$ sudo mkdir -p /etc/containerd
$ containerd config default | sudo tee /etc/containerd/config.toml
$ sudo systemctl restart containerd && sudo systemctl enable containerd
```
#### Установка kubectl, kubeadm, kubelet
на всех машинах:
```shell
$ sudo apt-get update && sudo apt-get install -y apt-transport-https curl
$ curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
$ echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
$ sudo apt update -y
$ sudo apt -y install vim git curl wget kubelet=1.23.0-00 kubeadm=1.23.0-00 kubectl=1.23.0-00
$ sudo apt-mark hold kubelet kubeadm kubectl
$ sudo kubeadm config images pull --cri-socket /run/containerd/containerd.sock --kubernetes-version v1.23.0
```

### Создание кластера

на мастер-ноде
``` shell
sudo kubeadm init \
  --apiserver-cert-extra-sans 62.84.119.214 \
  --pod-network-cidr=10.244.0.0/16 \
  --upload-certs \
  --kubernetes-version=v1.23.0 \
  --cri-socket /run/containerd/containerd.sock

...  
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:
```
```shell
kubeadm join 192.168.1.100:6443 --token token \
        --discovery-token-ca-cert-hash sha256:hash
```
 - Копируем конфиг kubectl
```shell
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

[akha@192 .kube]$ kubectl cluster-info
Kubernetes control plane is running at https://master:6443
CoreDNS is running at https://master:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```shell

#### Установим сетевой плагин
```shell
ubuntu@master:~$ kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
namespace/kube-flannel created
clusterrole.rbac.authorization.k8s.io/flannel created
clusterrolebinding.rbac.authorization.k8s.io/flannel created
serviceaccount/flannel created
configmap/kube-flannel-cfg created
daemonset.apps/kube-flannel-ds created

ubuntu@master:~$ kubectl get nodes -o wide
NAME     STATUS   ROLES                  AGE   VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
master   Ready 
```
#### Подключаем worker-ноды

получаем токен на мастере:
```shell
ubuntu@master:~$ sudo kubeadm token create --print-join-command
```
Выполняем на каждом воркере:
```shell
sudo kubeadm join master:6443 --token токен --discovery-token-ca-cert-hash sha256:хешш

ubuntu@master:~$ kubectl get nodes -o wide
NAME       STATUS 
master     Ready    
worker-1   Ready    
worker-2   Ready    
worker-3   Ready 
```shell
#### Запуск нагрузки
```shell
[akha@192 kubernetes-prod]$ kubectl apply -f nginx.yaml
[akha@192 kubernetes-prod]$ kubectl get pods -o wide
NAME                             READY   STATUS    RESTARTS   AGE   IP           NODE       NOMINATED NODE   READINESS GATES
nginx-deployment-8c9c5f4-6xq64   1/1     Running   0          33s   10.244.1.2   worker-1   <none>           <none>
nginx-deployment-8c9c5f4-pnsx4   1/1     Running   0          33s   10.244.2.2   worker-2   <none>           <none>
nginx-deployment-8c9c5f4-qczr9   1/1     Running   0          33s   10.244.3.2   worker-3   <none>           <none>
nginx-deployment-8c9c5f4-zdtcz   1/1     Running   0          33s   10.244.3.3   worker-3   <none>           <none>
```
### Обновление кластера
Сперва мастер, затем - воркеры
#### Обновление мастера
```shell
$ sudo apt update
$ apt-cache madison kubeadm
$ sudo apt-get install kubeadm='1.24.17-00' \
  -y \
  --allow-change-held-packages
$ sudo kubeadm upgrade plan
$ sudo kubeadm upgrade apply v1.24.17
[upgrade/successful] SUCCESS! Your cluster was upgraded to "v1.24.17". Enjoy!

[upgrade/kubelet] Now that your control plane is upgraded, please proceed with upgrading your kubelets if you haven't already done so.
```

Версия kubelet не изменилась
```shell
ubuntu@master:~$ kubectl get nodes
NAME       STATUS   ROLES           AGE     VERSION
master     Ready    control-plane   2d22h   v1.23.0
worker-1   Ready    <none>          2d22h   v1.23.0
worker-2   Ready    <none>          2d22h   v1.23.0
worker-3   Ready    <none>          2d22h   v1.23.0
```shell
Версия Api изменилась:
```shell
ubuntu@master:~$ kubectl version
Server Version: version.Info{Major:"1", Minor:"24", GitVersion:"v1.24.17"
```
#### Обновление остальных компонентов кластера
```shell
root@master:/home/ubuntu# kubeadm upgrade plan
...
[upgrade/versions] Target version: v1.24.17
[upgrade/versions] Latest version in the v1.24 series: v1.24.17
```
 - применяем изменения:
```shell
kubeadm upgrade apply v1.24.17
[upgrade/successful] SUCCESS! Your cluster was upgraded to "v1.24.17". Enjoy!
root@master:/home/ubuntu# kubeadm version
kubeadm version: &version.Info{Major:"1", Minor:"24", GitVersion:"v1.24.17", GitCommit:"22a9682c8fe855c321be75c5faacde343f909b04", GitTreeState:"clean", BuildDate:"2023-08-23T23:43:11Z", GoVersion:"go1.20.7", Compiler:"gc", Platform:"linux/amd64"}
root@master:/home/ubuntu# kubelet --version
Kubernetes v1.23.0
```
 - Обновим kubelet
```shell
sudo apt-get install kubelet='1.24.17-00' kubectl='1.24.17-00' \
  -y \
  --allow-change-held-packages 
sudo systemctl daemon-reload
sudo systemctl restart kubelet
ubuntu@master:~$ kubectl get nodes
NAME       STATUS   ROLES           AGE     VERSION
master     Ready    control-plane   2d22h   v1.24.17
worker-1   Ready    <none>          2d22h   v1.23.0
worker-2   Ready    <none>          2d22h   v1.23.0
worker-3   Ready    <none>          2d22h   v1.23.0
```
#### Обновление worker nodes

Операции выполняем на каждой из worker нод. Обновляем по очереди, сначала полностью одну ноду, и, после ее ввода в срой, - обновляем следующую.

снимаем нагрузку с ноды:
```shell
[akha@192 ~]$ kubectl drain worker-1 --ignore-daemonsets

...
node/worker-1 drained
[akha@192 ~]$ kubectl get nodes
NAME       STATUS                     ROLES           AGE     VERSION
master     Ready                      control-plane   2d23h   v1.24.17
worker-1   Ready,SchedulingDisabled   <none>          2d22h   v1.23.0
```

Обновляем kubeadm:
```shell
$ sudo apt update
$ apt-cache madison kubeadm
$ sudo apt-get install kubeadm='1.24.17-00' \
  -y \
  --allow-change-held-packages
$ sudo kubeadm upgrade node
[upgrade] The configuration for this node was successfully updated!
```
обновляем kubelet
```shell
$ sudo apt-get install kubelet='1.24.17-00' kubectl='1.24.17-00' \
  -y \
  --allow-change-held-packages
$ sudo systemctl daemon-reload
$ sudo systemctl restart kubelet
```
возвращаем нагрузку
```shell
[akha@192 ~]$ kubectl uncordon worker-1
node/worker-1 uncordoned
```
Смотрим результат

```shell
[akha@192 ~]$ kubectl get nodes
NAME       STATUS   ROLES           AGE     VERSION
master     Ready    control-plane   2d23h   v1.24.17
worker-1   Ready    <none>          2d23h   v1.24.17
worker-2   Ready    <none>          2d22h   v1.23.0
worker-3   Ready    <none>          2d22h   v1.23.0
```
повторяем на оставшихся двух нодах.
```shell
[akha@192 ~]$ kubectl get nodes
NAME       STATUS   ROLES           AGE     VERSION
master     Ready    control-plane   2d23h   v1.24.17
worker-1   Ready    <none>          2d23h   v1.24.17
worker-2   Ready    <none>          2d23h   v1.24.17
worker-3   Ready    <none>          2d23h   v1.24.17
```
### Автоматическое развертывание кластеров

Ставим python и pip
```shell
[akha@192 ~]$ sudo yum-install python3
[akha@192 ~]$ sudo yum install pip
[akha@192 ~]$ python3 -V
Python 3.9.18
[akha@192 ~]$ pip -V
pip 21.2.3 from /usr/lib/python3.9/site-packages/pip (python 3.9)
[akha@192 ~]$ pip3 install virtualenv
```
Пересоздаем ноды терраформом, назначем им внешние адреса.
SSH доступ на все ноды кластера - аналогично ручному развертыванию. 
#### Установка Kubespray
```shell
[akha@192 ~]$ git clone https://github.com/kubernetes-sigs/kubespray.git
[akha@192 kubespray]$ sudo pip install -r requirements.txt
[akha@192 kubespray]$ ansible --version
ansible [core 2.15.9]
  config file = /home/akha/kubespray/ansible.cfg
  configured module search path = ['/home/akha/kubespray/library']
  ansible python module location = /usr/local/lib/python3.9/site-packages/ansible
  ansible collection location = /home/akha/.ansible/collections:/usr/share/ansible/collections
  executable location = /usr/local/bin/ansible
  python version = 3.9.18 (main, Jan 24 2024, 00:00:00) [GCC 11.4.1 20231218 (Red Hat 11.4.1-3)] (/usr/bin/python3)
  jinja version = 3.1.2
  libyaml = True
```
 - копируем и правим iventory
```shell
mkdir -p kubernetes-prod/inventory/
```
Запускаем созадние кластера
```shell
ansible-playbook \
  -i ~/kubernetes-prod/inventory/inventory.ini \
  --become \
  --become-user=root \
  --user=ubuntu \
  --key-file=/home/akha/.ssh/akha-yc cluster.yml
```
 - A few moments later ...  
```shell
PLAY RECAP ***********************************************************************************************************************************************
master                     : ok=698  changed=144  unreachable=0    failed=0    skipped=1165 rescued=0    ignored=6
worker-1                   : ok=438  changed=88   unreachable=0    failed=0    skipped=697  rescued=0    ignored=1
worker-2                   : ok=438  changed=88   unreachable=0    failed=0    skipped=693  rescued=0    ignored=1
worker-3                   : ok=438  changed=88   unreachable=0    failed=0    skipped=693  rescued=0    ignored=1
```
 - Далее на мастере настраиваем конфиг:
```shell
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
 - и получаем инфу о нодах:
```shell
ubuntu@master:~$ kubectl get nodes -o wide
NAME       STATUS   ROLES           AGE     VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
master     Ready    control-plane   8m35s   v1.29.2   192.168.1.100   <none>        Ubuntu 20.04.6 LTS   5.4.0-169-generic   containerd://1.7.13
worker-1   Ready    <none>          7m54s   v1.29.2   192.168.1.201   <none>        Ubuntu 20.04.6 LTS   5.4.0-169-generic   containerd://1.7.13
worker-2   Ready    <none>          7m54s   v1.29.2   192.168.1.202   <none>        Ubuntu 20.04.6 LTS   5.4.0-169-generic   containerd://1.7.13
worker-3   Ready    <none>          7m49s   v1.29.2   192.168.1.203   <none>        Ubuntu 20.04.6 LTS   5.4.0-169-generic   containerd://1.7.13
```shell
 - Подаем нагрузку и проверяем успешность:
```shell
[akha@192 kubernetes-prod]$ kubectl apply -f nginx.yaml
deployment.apps/nginx-deployment created

[akha@192 kubernetes-prod]$ kubectl get po -o wide
NAME                                READY   STATUS    RESTARTS   AGE   IP               NODE       NOMINATED NODE   READINESS GATES
nginx-deployment-54b6986c8c-9c25d   1/1     Running   0          79s   10.233.105.194   worker-1   <none>           <none>
nginx-deployment-54b6986c8c-9wkx5   1/1     Running   0          79s   10.233.72.193    worker-2   <none>           <none>
nginx-deployment-54b6986c8c-v5ngp   1/1     Running   0          79s   10.233.72.194    worker-2   <none>           <none>
nginx-deployment-54b6986c8c-zt5lk   1/1     Running   0          79s   10.233.125.66    worker-3   <none>           <none>

```shell

## PR checklist:
 - [*] Выставлен label с темой домашнего задания
