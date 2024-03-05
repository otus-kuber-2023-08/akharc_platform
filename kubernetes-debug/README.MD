# akharc_platform
akharc Platform repository
# Выполнено ДЗ №13

 - [ ] Основное ДЗ



## В процессе сделано:
- опробована работа инструментов отладки и дебага


## Как проверить работоспособность:

Запущен кластер k8s в Yandex Cloud

### kubectl-debug
Оригинальный репо: https://github.com/aylei/kubectl-debug
Используем Форк: https://github.com/JamesTGrant/kubectl-debug и ephemeral containers


Отладим контейнер с Nginx:
``` shell
[akha@192 kubernetes-debug]$ kubectl run ephemeral-nginx --image=nginx --restart=Never

[akha@192 kubernetes-debug]$ kubectl debug -it ephemeral-nginx --image=alpine:latest --target=ephemeral-nginx

Targeting container "ephemeral-nginx". If you don't see processes from this container it may be because the container runtime doesn't support this feature.
Defaulting debug container name to debugger-d7jgq.
If you don't see a command prompt, try pressing enter.
/ #
```
Поставим в Ephemeral Container утилиту strace:
```shell
apk --update add strace

fetch https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/APKINDEX.tar.gz
fetch https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/APKINDEX.tar.gz
(1/7) Installing zstd-libs (1.5.5-r8)
(2/7) Installing libelf (0.190-r1)
(3/7) Installing libbz2 (1.0.8-r6)
(4/7) Installing musl-fts (1.2.7-r6)
(5/7) Installing xz-libs (5.4.5-r0)
(6/7) Installing libdw (0.190-r1)
(7/7) Installing strace (6.6-r0)
Executing busybox-1.36.1-r15.trigger
OK: 10 MiB in 22 packages

/ # strace ls
execve("/bin/ls", ["ls"], 0x7ffe41a62460 /* 14 vars */) = 0
arch_prctl(ARCH_SET_FS, 0x7fa450121b08) = 0
set_tid_address(0x7fa450121f70)         = 41
brk(NULL)                               = 0x559b07e64000
brk(0x559b07e66000)                     = 0x559b07e66000
mmap(0x559b07e64000, 4096, PROT_NONE, MAP_PRIVATE|MAP_FIXED|MAP_ANONYMOUS, -1, 0) = 0x559b07e64000
mprotect(0x7fa45011e000, 4096, PROT_READ) = 0
mprotect(0x559b0669f000, 16384, PROT_READ) = 0
getuid()                                = 0
ioctl(0, TIOCGWINSZ, {ws_row=48, ws_col=154, ws_xpixel=0, ws_ypixel=0}) = 0
ioctl(1, TIOCGWINSZ, {ws_row=48, ws_col=154, ws_xpixel=0, ws_ypixel=0}) = 0
ioctl(1, TIOCGWINSZ, {ws_row=48, ws_col=154, ws_xpixel=0, ws_ypixel=0}) = 0
stat(".", {st_mode=S_IFDIR|0755, st_size=4096, ...}) = 0
open(".", O_RDONLY|O_LARGEFILE|O_CLOEXEC|O_DIRECTORY) = 3
fcntl(3, F_SETFD, FD_CLOEXEC)           = 0
mmap(NULL, 8192, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0x7fa45007e000
getdents64(3, 0x7fa45007e038 /* 19 entries */, 2048) = 464
lstat("./home", {st_mode=S_IFDIR|0755, st_size=4096, ...}) = 0
lstat("./bin", {st_mode=S_IFDIR|0755, st_size=4096, ...}) = 0
lstat("./mnt", {st_mode=S_IFDIR|0755, st_size=4096, ...}) = 0
lstat("./run", {st_mode=S_IFDIR|0755, st_size=4096, ...}) = 0
lstat("./proc", {st_mode=S_IFDIR|0555, st_size=0, ...}) = 0
lstat("./dev", {st_mode=S_IFDIR|0755, st_size=380, ...}) = 0
lstat("./usr", {st_mode=S_IFDIR|0755, st_size=4096, ...}) = 0
lstat("./root", {st_mode=S_IFDIR|0700, st_size=4096, ...}) = 0
lstat("./sys", {st_mode=S_IFDIR|0555, st_size=0, ...}) = 0
lstat("./sbin", {st_mode=S_IFDIR|0755, st_size=4096, ...}) = 0
lstat("./tmp", {st_mode=S_IFDIR|S_ISVTX|0777, st_size=4096, ...}) = 0
lstat("./srv", {st_mode=S_IFDIR|0755, st_size=4096, ...}) = 0
lstat("./etc", {st_mode=S_IFDIR|0755, st_size=4096, ...}) = 0
lstat("./media", {st_mode=S_IFDIR|0755, st_size=4096, ...}) = 0
lstat("./lib", {st_mode=S_IFDIR|0755, st_size=4096, ...}) = 0
lstat("./var", {st_mode=S_IFDIR|0755, st_size=4096, ...}) = 0
lstat("./opt", {st_mode=S_IFDIR|0755, st_size=4096, ...}) = 0
getdents64(3, 0x7fa45007e038 /* 0 entries */, 2048) = 0
close(3)                                = 0
munmap(0x7fa45007e000, 8192)            = 0
ioctl(1, TIOCGWINSZ, {ws_row=48, ws_col=154, ws_xpixel=0, ws_ypixel=0}) = 0
writev(1, [{iov_base="\33[1;34mbin\33[m    \33[1;34mdev\33[m  "..., iov_len=285}, {iov_base="\n", iov_len=1}], 2bin    dev    etc    home   lib    media  mnt    opt    proc   root   run    sbin   srv    sys    tmp    usr    var
) = 286
exit_group(0)                           = ?
+++ exited with 0 +++
```
### iptables-tailer
Берем ресурсы из https://github.com/piontec/netperf-operator/tree/master/deploy согласно методичке
```shell
[akha@192 akharc_platform]$ kubectl apply -f kubernetes-debug/kit/crd.yaml
customresourcedefinition.apiextensions.k8s.io/netperfs.app.example.com created
[akha@192 akharc_platform]$ kubectl apply -f kubernetes-debug/kit/operator.yaml
deployment.apps/netperf-operator created
[akha@192 akharc_platform]$ kubectl apply -f kubernetes-debug/kit/rbac.yaml
role.rbac.authorization.k8s.io/netperf-operator created
rolebinding.rbac.authorization.k8s.io/default-account-netperf-operator created
```
Создаем Netperf ресурс
```shell
[akha@192 akharc_platform]$ kubectl apply -f kubernetes-debug/kit/cr.yaml

netperf.app.example.com/example created

[akha@192 akharc_platform]$ kubectl describe netperf.app.example.com/example
Name:         example
Namespace:    default
Labels:       <none>
Annotations:  <none>
API Version:  app.example.com/v1alpha1
Kind:         Netperf
Metadata:
  Creation Timestamp:  2024-03-04T13:06:16Z
  Generation:          1
  Resource Version:    7778
  UID:                 02ec1039-8b27-467f-98c4-1d8accaa5a44
Events:                <none>
```shell
## PR checklist:
 - [*] Выставлен label с темой домашнего задания