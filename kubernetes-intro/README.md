# akharc_platform
akharc Platform repository
# Выполнено ДЗ №1

 - [*] Основное ДЗ
 - [*] Задание со *

## В процессе сделано:
1.Разберитесь почему все pod в namespace kube-system восстановились после удаления. 
    
    1.а Pod coredns восстановился из-за использования механизма replica set, который восстанавливает его работу
    2.b Остальные поды - это static pods, работой которых управляет kubelet. kubelet заущен как сервис, соответственно, пока сервис работает - поды будут пересоздаваться.
    
    $ ls -l  /etc/kubernetes/manifests
    total 16
    -rw------- 1 root root 2476 May 13 17:31 etcd.yaml
    -rw------- 1 root root 3637 May 13 17:31 kube-apiserver.yaml
    -rw------- 1 root root 2951 May 13 17:31 kube-controller-manager.yaml
    -rw------- 1 root root 1441 May 13 17:31 kube-scheduler.yaml

    systemctl status kubelet

    ● kubelet.service - kubelet: The Kubernetes Node Agent
     Loaded: loaded (/usr/lib/systemd/system/kubelet.service; disabled; vendor preset: enabled)
    Drop-In: /etc/systemd/system/kubelet.service.d
             └─10-kubeadm.conf
     Active: active (running) since Sat 2023-05-13 17:31:02 UTC; 1h 1min ago
       Docs: http://kubernetes.io/docs/
    Main PID: 1243 (kubelet)
      Tasks: 11 (limit: 2218)
     Memory: 113.9M
     CGroup: /system.slice/kubelet.service
             └─1243 /var/lib/minikube/binaries/v1.26.3/kubelet --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --config=/var/lib/kub
2. POD с веб-сервером
    
    2.а Был создан Dockerfile на основе образа nginx:alpine, c uid  1001, который слушает на порту 8000. Образ запушен в Докерхаб:
    
      docker build -t nginx-otus-k8s .
      docker tag nginx-otus-k8s akha/otus-k8s
      docker push akha/otus-k8s
    
    2.b Создан манифест пода с init-контейнером и volumes на основе образа из предыдущего пункта.Содержимое доступно по адресу http://localhost:8000/
    
      kubectl apply -f web-pod.yaml
      kubectl port-forward --address 0.0.0.0 pod/web 8000:8000
3. Hipster Shop
    
    3.а Склонирован репо microservices-demo, собран образ hipster-frontend, запушен в Докерхаб, сформирован манифест для пода:
    
      docker build -t hipster-frontend-k8s .
      docker tag hipster-frontend-k8s akha/otus-frontend-k8s
      docker push akha/otus-frontend-k8s
      kubectl run frontend --image akha/otus-frontend-k8s --restart=Never  --dry-run -o yaml > frontend-pod.yaml 
    
    3.b ЗАДАНИЕ СО ЗВЕЗДОЧКОЙ. Под frontend не запускается, т.к. не описаны требуемые переменные окружения:
    
      panic: environment variable "PRODUCT_CATALOG_SERVICE_ADDR" not set

    Исправлено в манифесте frontend-pod-healthy.yaml
    
      kubectl apply -f frontend-pod-healthy.yaml
      [akha@192 kubernetes-intro]$ kubectl get pods
      NAME       READY   STATUS    RESTARTS   AGE
      frontend   1/1     Running   0          4s
## Как запустить проект:
##
## Как проверить работоспособность:
перейти по ссылке http://localhost:8080
## PR checklist:
 - [*] Выставлен label с темой домашнего задания
