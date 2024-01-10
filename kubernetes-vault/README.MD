/--------------------------------------------------------------
# akharc_platform
akharc Platform repository
# Выполнено ДЗ №11

 - [ ] Основное ДЗ
 - [ ] Задание со * 


## В процессе сделано:
- Установлен vault
- Научились базово работать с секретами через vault


## Как проверить работоспособность:

### Инсталляция hashicorp vault HA в k8s

 - Ставим consul и vault
```shell
git clone https://github.com/hashicorp/consul-k8s.git
helm upgrade --install consul consul --atomic
git clone https://github.com/hashicorp/vault-helm.git
helm upgrade --install vault vault-helm -f vault.values.yaml --atomic
```

```shell
[akha@192 kubernetes-vault]$ helm status vault
NAME: vault
LAST DEPLOYED: Tue Jan  2 23:51:46 2024
NAMESPACE: default
STATUS: deployed
REVISION: 1
NOTES:
Thank you for installing HashiCorp Vault!

Now that you have deployed Vault, you should look over the docs on using
Vault with Kubernetes available here:

https://developer.hashicorp.com/vault/docs


Your release is named vault. To learn more about the release, try:

  $ helm status vault
  $ helm get manifest vault



[akha@192 kubernetes-vault]$ kubectl get pods -o wide
NAME                                                READY   STATUS    RESTARTS       AGE     IP              NODE                        NOMINATED NODE   READINESS GATES
consul-consul-connect-injector-9564859d9-jthw4      1/1     Running   0              8m54s   192.168.4.181   cl1vssnst3jl49i1s2p7-efew   <none>           <none>
consul-consul-server-0                              1/1     Running   0              8m53s   192.168.4.180   cl1vssnst3jl49i1s2p7-efew   <none>           <none>
consul-consul-webhook-cert-manager-8b577d65-gsl9x   1/1     Running   0              8m54s   192.168.5.248   cl1vssnst3jl49i1s2p7-onol   <none>           <none>
gitlab-runner-7c88d47bdf-z5qhv                      1/1     Running   23 (11m ago)   10d     192.168.4.168   cl1vssnst3jl49i1s2p7-efew   <none>           <none>
vault-0                                             0/1     Running   0              29s     192.168.5.250   cl1vssnst3jl49i1s2p7-onol   <none>           <none>
vault-1                                             0/1     Running   0              28s     192.168.6.41    cl1vssnst3jl49i1s2p7-iqel   <none>           <none>
vault-2                                             0/1     Running   0              28s     192.168.4.182   cl1vssnst3jl49i1s2p7-efew   <none>           <none>
vault-agent-injector-66f6f958b6-l4lms               1/1     Running   0              29s     192.168.6.40    cl1vssnst3jl49i1s2p7-iqel   <none>           <none>
```


Статус Vault:
```shell
[akha@192 kubernetes-vault]$ alias vault='kubectl exec -it vault-0 -- vault'
[akha@192 kubernetes-vault]$ vault status
Key                Value
---                -----
Seal Type          shamir
Initialized        false
Sealed             true
Total Shares       0
Threshold          0
Unseal Progress    0/0
Unseal Nonce       n/a
Version            1.15.2
Build Date         2023-11-06T11:33:28Z
Storage Type       consul
HA Enabled         true
command terminated with exit code 2

[akha@192 ~]$ helm status vault
NAME: vault
LAST DEPLOYED: Tue Jan  2 23:51:46 2024
NAMESPACE: default
STATUS: deployed
REVISION: 1
NOTES:
Thank you for installing HashiCorp Vault!

Now that you have deployed Vault, you should look over the docs on using
Vault with Kubernetes available here:

https://developer.hashicorp.com/vault/docs


Your release is named vault. To learn more about the release, try:

  $ helm status vault
  $ helm get manifest vault


```
 - Инициализируем Vault и распечатываем первый под
```shell 
$ vault operator init -key-shares=1 -key-threshold=1 -format=json > cluster-keys.json
$ VAULT_UNSEAL_KEY=$(cat cluster-keys.json | jq -r ".unseal_keys_b64[]")
[akha@192 kubernetes-vault]$ VAULT_UNSEAL_KEY=ключ в base64
[akha@192 kubernetes-vault]$ vault operator unseal $VAULT_UNSEAL_KEY
Key                    Value
---                    -----
Seal Type              shamir
Initialized            true
Sealed                 false
Total Shares           1
Threshold              1
Version                1.15.2
Build Date             2023-11-06T11:33:28Z
Storage Type           consul
Cluster Name           vault-cluster-419029b2
HA Enabled             true
HA Cluster             n/a
HA Mode                standby
Active Node Address    <none>
```

Распечатываем 2 и 3 поды
```shell
[akha@192 kubernetes-vault]$ kubectl exec vault-1 -- vault operator unseal $VAULT_UNSEAL_KEY
Key                    Value
---                    -----
Seal Type              shamir
Initialized            true
Sealed                 false
Total Shares           1
Threshold              1
Version                1.15.2
Build Date             2023-11-06T11:33:28Z
Storage Type           consul
Cluster Name           vault-cluster-419029b2
HA Enabled             true
HA Cluster             https://vault-0.vault-internal:8201
HA Mode                standby
Active Node Address    http://192.168.5.199:8200

[akha@192 kubernetes-vault]$ kubectl exec vault-2 -- vault operator unseal $VAULT_UNSEAL_KEY
Key                    Value
---                    -----
Seal Type              shamir
Initialized            true
Sealed                 false
Total Shares           1
Threshold              1
Version                1.15.2
Build Date             2023-11-06T11:33:28Z
Storage Type           consul
Cluster Name           vault-cluster-419029b2
HA Enabled             true
HA Cluster             https://vault-0.vault-internal:8201
HA Mode                standby
Active Node Address    http://192.168.5.199:8200

[akha@192 kubernetes-vault]$ vault status
Key             Value
---             -----
Seal Type       shamir
Initialized     true
Sealed          false
Total Shares    1
Threshold       1
Version         1.15.2
Build Date      2023-11-06T11:33:28Z
Storage Type    consul
Cluster Name    vault-cluster-419029b2
HA Enabled      true
HA Cluster      https://vault-0.vault-internal:8201
HA Mode         active
Active Since    2024-01-05T19:57:37.611660833Z

```

Логинимся:
```shell
[akha@192 kubernetes-vault]$ kubectl exec -it vault-0 -- vault auth list
Error listing enabled authentications: Error making API request.

[akha@192 kubernetes-vault]$ vault login
Token (will be hidden):
Success! You are now authenticated. The token information displayed below
is already stored in the token helper. You do NOT need to run "vault login"
again. Future Vault requests will automatically use this token.

Key                  Value
---                  -----
...
token_duration       ∞
token_renewable      false
token_policies       ["root"]
identity_policies    []
policies             ["root"]


[akha@192 kubernetes-vault]$ kubectl exec -it vault-0 -- vault auth list
Path      Type     Accessor               Description                Version
----      ----     --------               -----------                -------
token/    token    auth_token_c9bfa19e    token based credentials    n/a

```

### Работа с секретами
Создаем:
```shell
[akha@192 kubernetes-vault]$ vault secrets enable --path=otus kv
Success! Enabled the kv secrets engine at: otus/
[akha@192 kubernetes-vault]$ vault secrets list --detailed
Path          Plugin       Accessor              Default TTL    Max TTL    Force No Cache    Replication    Seal Wrap    External Entropy Access    Options    Description                                                UUID                                    Version    Running Version          Running SHA256    Deprecation Status
----          ------       --------              -----------    -------    --------------    -----------    ---------    -----------------------    -------    -----------                                                ----                                    -------    ---------------          --------------    ------------------
cubbyhole/    cubbyhole    cubbyhole_35bdcc4a    n/a            n/a        false             local          false        false                      map[]      per-token private secret storage                           50ffa577-b2a2-3e8f-2903-bfe62b215758    n/a        v1.15.2+builtin.vault    n/a               n/a
identity/     identity     identity_7e4644c3     system         system     false             replicated     false        false                      map[]      identity store                                             2c186421-e3d2-7a61-fc5e-804d9f7d3942    n/a        v1.15.2+builtin.vault    n/a               n/a
otus/         kv           kv_24081726           system         system     false             replicated     false        false                      map[]      n/a                                                        9fabef63-026e-273c-a126-c9d77b2c14ee    n/a        v0.16.1+builtin          n/a               supported
sys/          system       system_d7377557       n/a            n/a        false             replicated     true         false                      map[]      system endpoints used for control, policy and debugging    f123e247-7d25-d45e-4670-a61e7a0050a0    n/a        v1.15.2+builtin.vault    n/a               n/a

[akha@192 kubernetes-vault]$ vault kv put otus/otus-ro/config username='otus' password='asajkjkahs'
Success! Data written to: otus/otus-ro/config
[akha@192 kubernetes-vault]$ vault kv put otus/otus-rw/config username='otus' password='asajkjkahs'
Success! Data written to: otus/otus-rw/config

[akha@192 kubernetes-vault]$ vault read otus/otus-ro/config
Key                 Value
---                 -----
refresh_interval    768h
password            asajkjkahs
username            otus

[akha@192 kubernetes-vault]$ vault kv get otus/otus-rw/config
====== Data ======
Key         Value
---         -----
password    asajkjkahs
username    otus

```


### авторизация черерз k8s
```shell
[akha@192 kubernetes-vault]$ vault auth enable kubernetes
Success! Enabled kubernetes auth method at: kubernetes/
[akha@192 kubernetes-vault]$ vault auth list
Path           Type          Accessor                    Description                Version
----           ----          --------                    -----------                -------
kubernetes/    kubernetes    auth_kubernetes_01a274e4    n/a                        n/a
token/         token         auth_token_c9bfa19e         token based credentials    n/a
```

 - Создаем и применяем манифест для CRB и Service Account

```shell
[akha@192 kubernetes-vault]$ kubectl apply --filename vault-auth-service-account.yaml
clusterrolebinding.rbac.authorization.k8s.io/role-tokenreview-binding created
serviceaccount/vault-auth created
secret/vault-auth-secret created
```

 - Настрока переменных
```shell
[akha@192 kubernetes-vault]$ export SA_SECRET_NAME=$(kubectl get secrets --output=json    | jq -r '.items[].metadata | select(.name|startswith("vault-auth-")).name')
[akha@192 kubernetes-vault]$ export SA_JWT_TOKEN=$(kubectl get secret $SA_SECRET_NAME -o jsonpath="{.data.token}" | base64 --decode; echo)
[akha@192 kubernetes-vault]$ export SA_CA_CRT=$(kubectl config view --raw --minify --flatten   --output 'jsonpath={.clusters[].cluster.certificate-authority-data}' | base64 --decode)
[akha@192 kubernetes-vault]$ export K8S_HOST=$(kubectl config view --raw --minify --flatten   --output 'jsonpath={.clusters[].cluster.server}')
[akha@192 kubernetes-vault]$ vault write auth/kubernetes/config token_reviewer_jwt="$SA_JWT_TOKEN" kubernetes_host="$K8S_HOST" kubernetes_ca_cert="$SA_CA_CRT" issuer="https://kubernetes.default.svc.cluster.local"
Success! Data written to: auth/kubernetes/config
```

 - Создадим политику
Создаем файл otus-policy.hcl, применяем:
```shell
[akha@192 kubernetes-vault]$ kubectl cp --no-preserve=false otus-policy.hcl vault-0:/tmp
[akha@192 kubernetes-vault]$ vault policy write otus-policy /tmp/otus-policy.hcl
Success! Uploaded policy: otus-policy
[akha@192 kubernetes-vault]$ vault write auth/kubernetes/role/otus bound_service_account_names=vault-auth bound_service_account_namespaces=default token_policies=otus-policy ttl=24h
Success! Data written to: auth/kubernetes/role/otus
```
 - проверяем работу:
создаем под: 
```shell
 [akha@192 kubernetes-vault]$ kubectl apply -f vault-pod.yaml
pod/vault-test created
[akha@192 kubernetes-vault]$ kubectl exec -it vault-test -- sh
# curl http://vault:8200/v1/sys/seal-status
{"type":"shamir","initialized":true,"sealed":false,"t":1,"n":1,"progress":0,"nonce":"","version":"1.15.2","build_date":"2023-11-06T11:33:28Z","migration":false,"cluster_name":"vault-cluster-419029b2","cluster_id":"2f8efead-c2a2-659b-07a4-a7269a300a05","recovery_seal":false,"storage_type":"consul"}
# KUBE_TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
# curl --request POST --data '{"jwt": "'$KUBE_TOKEN'", "role": "otus"}' $VAULT_ADDR/v1/auth/kubernetes/login | jq
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  1724  100   749  100   975  15479  20149 --:--:-- --:--:-- --:--:-- 35916
{
  "request_id": "63fe9a7d-47cc-3afa-aa40-125c898e9182",
  "lease_id": "",
  "renewable": false,
  "lease_duration": 0,
  "data": null,
  "wrap_info": null,
  "warnings": null,
  "auth": {
    "client_token": "токен",
    "accessor": "токен",
    "policies": [
      "default",
      "otus-policy"
    ],
    "token_policies": [
      "default",
      "otus-policy"
    ],
    "metadata": {
      "role": "otus",
      "service_account_name": "vault-auth",
      "service_account_namespace": "default",
      "service_account_secret_name": "",
      "service_account_uid": "93923bad-c9c2-4f1d-9803-1cb1421969c4"
    },
    "lease_duration": 86400,
    "renewable": true,
    "entity_id": "96f2cb6a-37f0-7b52-49e9-195c24b5c424",
    "token_type": "service",
    "orphan": true,
    "mfa_requirement": null,
    "num_uses": 0
  }
}
TOKEN=$(curl -k -s --request POST --data '{"jwt": "'$KUBE_TOKEN'", "role": "otus"}' $VAULT_ADDR/v1/auth/kubernetes/login | jq '.auth.client_token' | awk -F\" '{print $2}')

```

Проверяем чтение секретов:
```shell
# curl -s  --header "X-Vault-Token:${TOKEN}" $VAULT_ADDR/v1/otus/otus-ro/config | jq
{
  "request_id": "ea2c8e4a-e134-09d7-c3bb-208b1715756d",
  "lease_id": "",
  "renewable": false,
  "lease_duration": 2764800,
  "data": {
    "password": "asajkjkahs",
    "username": "otus"
  },
  "wrap_info": null,
  "warnings": null,
  "auth": null
}
# curl --request POST --data '{"bar": "baz"}' --header "X-Vault-Token:${TOKEN}" $VAULT_ADDR/v1/otus/otus-ro/config 
{"errors":["1 error occurred:\n\t* permission denied\n\n"]}
# curl --request POST --data '{"bar": "baz"}' --header "X-Vault-Token:${TOKEN}" $VAULT_ADDR/v1/otus/otus-rw/config
{"errors":["1 error occurred:\n\t* permission denied\n\n"]}
# curl --request POST --data '{"bar": "baz"}' --header "X-Vault-Token:${TOKEN}" $VAULT_ADDR/v1/otus/otus-rw/config1
```

Чтение работает, в отличии от обновления.
Вопрос: Почему мы смогли записать otus-rw/config1 но не смогли otus-rw/config?
Ответ: В политике не задано правило update
после изменения и применения политики ключ обновился:
```shell
# curl --request POST --data '{"bar": "baz"}' --header "X-Vault-Token:${TOKEN}" $VAULT_ADDR/v1/otus/otus-rw/config
# curl -s --header "X-Vault-Token:${TOKEN}" $VAULT_ADDR/v1/otus/otus-rw/config | jq
{
  "request_id": "3e1d292b-d706-312d-5045-9d10ba7a6981",
  "lease_id": "",
  "renewable": false,
  "lease_duration": 2764800,
  "data": {
    "bar": "baz"
  },
  "wrap_info": null,
  "warnings": null,
  "auth": null
}
```

### Use case использования авторизации через k8s
- Исправляем configmap vault-agent, деплоим vault-agent и тестовый под
```shell
[akha@192 kubernetes-vault]$ kubectl create configmap example-vault-agent-config --from-file=./configs-k8s/
configmap/example-vault-agent-config created
[akha@192 kubernetes-vault]$ kubectl get configmap example-vault-agent-config -o yaml
akha@192 kubernetes-vault]$ kubectl apply -f example-k8s-spec.yaml --record
pod/vault-agent-example created
```
Проверяем. Init-контейнер с Vault-agent сходил в Vault, достал секреты и записал их на стартовой странице Nginx
```shell
[akha@192 kubernetes-vault]$ kubectl exec -it vault-agent-example -- sh
Defaulted container "nginx-container" out of: nginx-container, vault-agent (init)
# cat /usr/share/nginx/html/index.html
<html>
<body>
<p>Some secrets:</p>
<ul>
<li><pre>username: otus</pre></li>
<li><pre>password: asajkjkahs</pre></li>
</ul>

</body>
</html>
```
### Работа с CA

 - Включим pki секретс
```shell
[akha@192 kubernetes-vault]$ vault secrets enable pki
Success! Enabled the pki secrets engine at: pki/
[akha@192 kubernetes-vault]$ vault secrets tune -max-lease-ttl=87600h pki
Success! Tuned the secrets engine at: pki/
[akha@192 kubernetes-vault]$ vault write -field=certificate pki/root/generate/internal common_name="akha.example.com" ttl=87600h > CA_cert.crt
```
Пропишем URL-ы и СА для отозванных сертификатов:
```shell
[akha@192 kubernetes-vault]$ vault write pki/config/urls issuing_certificates="http://vault:8200/v1/pki/ca" crl_distribution_points="http://vault:8200/v1/pki/crl"
Key                        Value
---                        -----
crl_distribution_points    [http://vault:8200/v1/pki/crl]
enable_templating          false
issuing_certificates       [http://vault:8200/v1/pki/ca]
ocsp_servers               []
```
Создадим промежуточный сертификат и сохраним все сертификаты CA в Vault:
```shell
[akha@192 kubernetes-vault]$ vault secrets enable --path=pki_int pki
Success! Enabled the pki secrets engine at: pki_int/
[akha@192 kubernetes-vault]$ vault secrets tune -max-lease-ttl=87600h pki_int
Success! Tuned the secrets engine at: pki_int/
[akha@192 kubernetes-vault]$ vault write -format=json pki_int/intermediate/generate/internal common_name="akha.example.com Intermediate Authority" | jq -r '.data.csr' > pki_intermediate.csr
[akha@192 kubernetes-vault]$ kubectl cp pki_intermediate.csr vault-0:/tmp
[akha@192 kubernetes-vault]$ vault write -format=json pki/root/sign-intermediate csr=@/tmp/pki_intermediate.csr format=pem_bundle ttl="43800h" | jq -r '.data.certificate' > intermediate.cert.pem
[akha@192 kubernetes-vault]$ kubectl cp intermediate.cert.pem vault-0:/tmp
[akha@192 kubernetes-vault]$ vault write pki_int/intermediate/set-signed certificate=@/tmp/intermediate.cert.pem
WARNING! The following warnings were returned from Vault:

  * This mount hasn't configured any authority information access (AIA)
  fields; this may make it harder for systems to find missing certificates
  in the chain or to validate revocation status of certificates. Consider
  updating /config/urls or the newly generated issuer with this information.

Key                 Value
---                 -----
existing_issuers    <nil>
existing_keys       <nil>
imported_issuers    [7f55c1c1-d8cc-9685-10d4-98d5d458f0a0 8a734b13-3a35-1800-8dab-a37b4673b992]
imported_keys       <nil>
mapping             map[7f55c1c1-d8cc-9685-10d4-98d5d458f0a0:b1f02c30-a073-7056-8edb-3d14c615d997 8a734b13-3a35-1800-8dab-a37b4673b992:]
```


Создадим роль для выдачи сертификатов:
```shell
[akha@192 kubernetes-vault]$ vault write pki_int/roles/vault-voytenkov-ru    allowed_domains="akha.example.com" allow_subdomains=true max_ttl="720h"
Key                                   Value
---                                   -----
allow_any_name                        false
allow_bare_domains                    false
allow_glob_domains                    false
allow_ip_sans                         true
allow_localhost                       true
allow_subdomains                      true
allow_token_displayname               false
allow_wildcard_certificates           true
allowed_domains                       [akha.example.com]
allowed_domains_template              false
allowed_other_sans                    []
allowed_serial_numbers                []
allowed_uri_sans                      []
allowed_uri_sans_template             false
allowed_user_ids                      []
basic_constraints_valid_for_non_ca    false
client_flag                           true
cn_validations                        [email hostname]
code_signing_flag                     false
country                               []
email_protection_flag                 false
enforce_hostnames                     true
ext_key_usage                         []
ext_key_usage_oids                    []
generate_lease                        false
issuer_ref                            default
key_bits                              2048
key_type                              rsa
key_usage                             [DigitalSignature KeyAgreement KeyEncipherment]
locality                              []
max_ttl                               720h
no_store                              false
not_after                             n/a
not_before_duration                   30s
organization                          []
ou                                    []
policy_identifiers                    []
postal_code                           []
province                              []
require_cn                            true
server_flag                           true
signature_bits                        256
street_address                        []
ttl                                   0s
use_csr_common_name                   true
use_csr_sans                          true
use_pss                               false
```
Выпустим сертификат:
```shell
[akha@192 kubernetes-vault]$ vault write pki_int/issue/vault-voytenkov-ru common_name="*.akha.example.com" ttl="24h"
Key                 Value
---                 -----
ca_chain            [-----BEGIN CERTIFICATE-----
MIIDqDCCApCgAwIBAgIUIIkqysMtWRlXUNrCIs4pEGWxz9IwDQYJKoZIhvcNAQEL
BQAwGzEZMBcGA1UEAxMQYWtoYS5leGFtcGxlLmNvbTAeFw0yNDAxMDcyMTMwMDRa
Fw0yOTAxMDUyMTMwMzRaMDIxMDAuBgNVBAMTJ2FraGEuZXhhbXBsZS5jb20gSW50
ZXJtZWRpYXRlIEF1dGhvcml0eTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
ggEBANRmLu9e+ccUFY650dJsafmqPQuVqQTdHhlHK7cnechoN4ZErCZJjiNUS//c
4tSBXC4Fa78BiiRMdIO4qv57pLbyUjJsYPtB7gFrE1iXcblDV/Oe5fTJCJYAdq7c
Ltl4oROALffmLAl1aV2Mm9nSVIOKDZI0aed4sznS9GxzMGG9KuEGUSI8X2Wl43tK
EiyIMROcJjbJzYbhsm06GUa0tk7kOGuS3gBbo7kyxfr8COh8XTfsyK2pn/t7WLFC
/jHbiXPG5/AmlCca4I11UBnUDDqntgkBi0p4mt/L5Dp3KeYMcegzHSPlNdoKP4lD
vvPFEjxXAVZnYhRecSV0MkgZ010CAwEAAaOBzDCByTAOBgNVHQ8BAf8EBAMCAQYw
DwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQUFCpkSjdXiv/t5sjeh+Mn5OHCmG8w
HwYDVR0jBBgwFoAUb5CKG+wr3igkeb/+0QkRLnXFXE8wNwYIKwYBBQUHAQEEKzAp
MCcGCCsGAQUFBzAChhtodHRwOi8vdmF1bHQ6ODIwMC92MS9wa2kvY2EwLQYDVR0f
BCYwJDAioCCgHoYcaHR0cDovL3ZhdWx0OjgyMDAvdjEvcGtpL2NybDANBgkqhkiG
9w0BAQsFAAOCAQEATc2pA4wUkapEO8MjF4DzSECGcAYEf+OSmOZU6f1m3igUsSRt
6wN5VeOYglFHtfYfh5qVvnin88d6ph+4Tnue4Cya+G6D7ikbexmZz7hcIfOEHoi3
860vtjb+W1wS9KnRiUXTV4ge/sk64xvIAJwOiLCrGqCMo2yCntcMKZwT/CgGMrDn
R86GReQMcMhCH3l6GfW8yCg7wRpdnrUnyn8HfJjBXFoVv3MSoXQCxjOpgcmZL10W
3+rZhwtKnrKY9aHWI3Sq/mHg5XEdOl6088pmn431mTzV5gWAvDZxdFsWFN4BQPPm
CIMUQbHZpGLS9M7pPzIHURfJ96HoQd2j1htfSQ==
-----END CERTIFICATE----- -----BEGIN CERTIFICATE-----
MIIDRTCCAi2gAwIBAgIUI2gdVGd7IZbQuhUYqUEpQHrsLm0wDQYJKoZIhvcNAQEL
BQAwGzEZMBcGA1UEAxMQYWtoYS5leGFtcGxlLmNvbTAeFw0yNDAxMDcyMTI3NDNa
Fw0zNDAxMDQyMTI4MTNaMBsxGTAXBgNVBAMTEGFraGEuZXhhbXBsZS5jb20wggEi
MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCkoQgiTzqHvBfW/nj/9B5jtT+L
AIhU6S4uTac7a+VzoR4xN9ToJCK5PXBtv2EdGh9EHGB3qyfKVmzVhGaZyM2TQTmA
OYdLtZ96TH/pYnUNM2i4kILDE6vH6c1AK9sSiJfng5gAI3IvI2bquVKpRzRBQOjD
dZVvBryJtiTFUfnDubttoronsnfIIzcV978KOOx8xGVxaBTD5aUPYh9dkMM/jfL2
Bdw+dxJJoENzUkmZcxcEyb/UelyoU+el/OsK8LartmZSp/JzS/HRpUlVJ/WsCAFz
2ggM4sRjEkXwuxdm3ZUnUgt8Oa7U/uJ7m/VwIOY/8bsUrMhBoPK3chSUC3XPAgMB
AAGjgYAwfjAOBgNVHQ8BAf8EBAMCAQYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4E
FgQUb5CKG+wr3igkeb/+0QkRLnXFXE8wHwYDVR0jBBgwFoAUb5CKG+wr3igkeb/+
0QkRLnXFXE8wGwYDVR0RBBQwEoIQYWtoYS5leGFtcGxlLmNvbTANBgkqhkiG9w0B
AQsFAAOCAQEAXOJEHUG+59MQ9Z5jvm2PzWTdFtFP6imD0mIByx8osYOiS/9O4u+n
8TS879kJBtaJV+Ibx8ph9vMuYK/mHjPxxEAdHTLNqxFmzdBaSiioHhH8wn+3OMHJ
Hb27qCARWxzNVPrqKEPhWQ7o1umge248w3sWhiDEXrSVQ7n/Tpwkl36NQDiL4MwO
JaWVoyQBUaVc7/meboCr4XI/IiJXV6r7T5K5eS8dT/OXVniEPKeGdbCiXs1fOXUO
dLLO+oby3Z1VsJLM0IXjRnEmb6yaVYF78/wI9J4VfjzSaX93zeB9N5gVsnemINFv
IxmhIXCNc8/5Ormde2UGwkoI4DHoI6s+Vw==
-----END CERTIFICATE-----]
certificate         -----BEGIN CERTIFICATE-----
MIIDbzCCAlegAwIBAgIUXkbYdL8BEfmwcPN2hZGZouXWKqIwDQYJKoZIhvcNAQEL
BQAwMjEwMC4GA1UEAxMnYWtoYS5leGFtcGxlLmNvbSBJbnRlcm1lZGlhdGUgQXV0
aG9yaXR5MB4XDTI0MDEwNzIxMzI1MVoXDTI0MDEwODIxMzMyMVowHTEbMBkGA1UE
AwwSKi5ha2hhLmV4YW1wbGUuY29tMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIB
CgKCAQEAsz/v2iWkWFF45cZgIIggzBaAhAAoJpwey4BRDXUDtIS/Qr07dj+q8T/r
YRhIeq6WwBMwTMRrd3ZB2WmLqaNlZKRFG94h3gNfydDKkD0MoP80JFS4m/VWEoKD
BGgKJQC8wCnxU4y+gdXpnFNuFvdGwAckm9xHwt8U3TjP7TU8iLLwF1HYbbt215J6
tI0+uA4BGwADbiTQvVM+yFkeLrjyDdCMlnuSN5K9HTst9GBJNEPwbqp/tuBUdgdq
FDHxEtlp6yGe4yKbHWvHw2MHXrOH+ce/a6L3yfUApxOuAGFFx/aUBE52Flhqokmv
cLvUbUHQ4PUKEgE9w3Q6bKuusqG6IwIDAQABo4GRMIGOMA4GA1UdDwEB/wQEAwID
qDAdBgNVHSUEFjAUBggrBgEFBQcDAQYIKwYBBQUHAwIwHQYDVR0OBBYEFBxGKXs9
leq8Zcp+R7CyVEP1CGvKMB8GA1UdIwQYMBaAFBQqZEo3V4r/7ebI3ofjJ+Thwphv
MB0GA1UdEQQWMBSCEiouYWtoYS5leGFtcGxlLmNvbTANBgkqhkiG9w0BAQsFAAOC
AQEAWTxKvdZreKfwVBBI8Wb5Tw0smNdz/HWVwblW9/U084gatmXtj2mf5fVmuIRF
c7io9Ie5zPr72WGDdU1omI/0DnoSS/r6F0EovDNLV2CC7MX0l2+jb+KE4tgTJkgK
4qeW5jBGH4O8WeGWMh14Q9fs8u5WhJ4MybC5SwmGYy6+075JIF+U+OHwjX84x7bh
iwsn1prhrfYx7ZMhYikELanxSUwgyqKKNSShYRDXDpgpJa84GRYE6DT3jysJ87VV
nZMiW/8WCgxrFOGURIIG5IXtMLv2S4nDtqKLLiKMMRzwSByVkcx4UEWyAq+usG7T
8QQMRT3YmEOD9l/WGUI0wYNziw==
-----END CERTIFICATE-----
expiration          1704749601
issuing_ca          -----BEGIN CERTIFICATE-----
MIIDqDCCApCgAwIBAgIUIIkqysMtWRlXUNrCIs4pEGWxz9IwDQYJKoZIhvcNAQEL
BQAwGzEZMBcGA1UEAxMQYWtoYS5leGFtcGxlLmNvbTAeFw0yNDAxMDcyMTMwMDRa
Fw0yOTAxMDUyMTMwMzRaMDIxMDAuBgNVBAMTJ2FraGEuZXhhbXBsZS5jb20gSW50
ZXJtZWRpYXRlIEF1dGhvcml0eTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
ggEBANRmLu9e+ccUFY650dJsafmqPQuVqQTdHhlHK7cnechoN4ZErCZJjiNUS//c
4tSBXC4Fa78BiiRMdIO4qv57pLbyUjJsYPtB7gFrE1iXcblDV/Oe5fTJCJYAdq7c
Ltl4oROALffmLAl1aV2Mm9nSVIOKDZI0aed4sznS9GxzMGG9KuEGUSI8X2Wl43tK
EiyIMROcJjbJzYbhsm06GUa0tk7kOGuS3gBbo7kyxfr8COh8XTfsyK2pn/t7WLFC
/jHbiXPG5/AmlCca4I11UBnUDDqntgkBi0p4mt/L5Dp3KeYMcegzHSPlNdoKP4lD
vvPFEjxXAVZnYhRecSV0MkgZ010CAwEAAaOBzDCByTAOBgNVHQ8BAf8EBAMCAQYw
DwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQUFCpkSjdXiv/t5sjeh+Mn5OHCmG8w
HwYDVR0jBBgwFoAUb5CKG+wr3igkeb/+0QkRLnXFXE8wNwYIKwYBBQUHAQEEKzAp
MCcGCCsGAQUFBzAChhtodHRwOi8vdmF1bHQ6ODIwMC92MS9wa2kvY2EwLQYDVR0f
BCYwJDAioCCgHoYcaHR0cDovL3ZhdWx0OjgyMDAvdjEvcGtpL2NybDANBgkqhkiG
9w0BAQsFAAOCAQEATc2pA4wUkapEO8MjF4DzSECGcAYEf+OSmOZU6f1m3igUsSRt
6wN5VeOYglFHtfYfh5qVvnin88d6ph+4Tnue4Cya+G6D7ikbexmZz7hcIfOEHoi3
860vtjb+W1wS9KnRiUXTV4ge/sk64xvIAJwOiLCrGqCMo2yCntcMKZwT/CgGMrDn
R86GReQMcMhCH3l6GfW8yCg7wRpdnrUnyn8HfJjBXFoVv3MSoXQCxjOpgcmZL10W
3+rZhwtKnrKY9aHWI3Sq/mHg5XEdOl6088pmn431mTzV5gWAvDZxdFsWFN4BQPPm
CIMUQbHZpGLS9M7pPzIHURfJ96HoQd2j1htfSQ==
-----END CERTIFICATE-----
private_key         -----BEGIN RSA PRIVATE KEY-----
MIIEpgIBAAKCAQEAsz/v2iWkWFF45cZgIIggzBaAhAAoJpwey4BRDXUDtIS/Qr07
dj+q8T/rYRhIeq6WwBMwTMRrd3ZB2WmLqaNlZKRFG94h3gNfydDKkD0MoP80JFS4
m/VWEoKDBGgKJQC8wCnxU4y+gdXpnFNuFvdGwAckm9xHwt8U3TjP7TU8iLLwF1HY
bbt215J6tI0+uA4BGwADbiTQvVM+yFkeLrjyDdCMlnuSN5K9HTst9GBJNEPwbqp/
tuBUdgdqFDHxEtlp6yGe4yKbHWvHw2MHXrOH+ce/a6L3yfUApxOuAGFFx/aUBE52
FlhqokmvcLvUbUHQ4PUKEgE9w3Q6bKuusqG6IwIDAQABAoIBAQCtl/UEkkHYGob4
GCdOOidxHzW1IKXBxp54PLvCSZmeAJVt3++vNDerzlh5Ptgqn9x1BeBX6D2fgxKA
qJvOXOS8E+6t73FjHmds/ty91bHeVWk86iOjPnTuFiEmak+wyEcD31rMrFhvSygj
8hSC/1UwcXp9y1ZgHkWJfRS5SD5orytSNP/TSwDq27fp3YVKbv5ANAWGODOeI7uO
O0iv7cGMk9053LsNsRVA9551iB1f6fX8r/s3h9V/WtFUbg21Q0uv+eP9VoJUFl5A
q7E/5fXwqVIK3tUILisyvVcIk+RNwPpxolfYMD0biGvcW7eWgwaPAmn297c5Oceo
vpycm4aZAoGBAN+mlT6ZS2YQxzNU+cuOPHrvatlcm4q6m8zrlDarLJjWPdDvusv9
gpvIDHEjmjz+WThM3lAjXLUVYHL5/aXA72Lg+LhRL6DAOkmQT/SLeFW2VWq3kstJ
YNumHFq3Wf0dfIpnvrQn/3xB2l1FG3aIyZR3j6+RywJRtwWTiALtCqP3AoGBAM0t
QnSRSAASCzntbVpn+A6cBsnDtzUNc8bMmoqLsKTLeHnXq8rmX0FB5iptqTeEj12f
Wv/HEM9TnWIMdvmTlT+QRjEbjYWEJEYgSW7QYPRKcZDSR0Nne04Ql/eRkhR0QwMg
mAc7XbayFQe/9XT7rganTkEEDx1pThroKKvJfng1AoGBAJyyHSzfwIkBRl/7sIxi
2pMTfZxPGxdmyVQY1h47biKjMGpcHFdiBglZbwYx+JW1axNcIAKr0/93u7yy1Hk2
pUJ09y5Ei4coR25VMv/WW/hJqKz9c1cE0VzzlDgm8GC8MQ7TwzR8Na98gB8LFUPG
cN2Zq01Ka57zW7UHear7I5JfAoGBAJZruw/Yvw+GKwLSBVzFYn/bdcKQIQ3dCedS
c25lUSDQJ0g0jLcZQ/aEyKiMcwXHwo+h18YzfChzpauPdd4ti7rpG/y+tXeQVEOx
QgTi8mHG/hFtiF9rS2QFGFShPZaPUd3GFI8gv+jEEFT5L4wPRBuOpvlVb3thi6iA
Uej3tSeNAoGBAM3PRdlmgTnmt2qAe2T2B8OENotNSBm/qKS0rc+kLaZiokJZ6U1P
IXwW4wYmSJuBpBt8HNGJBZLMupnQQuEmsDUvHVZlvs4LTu2oXeefTNEIp6lzRHSj
te6doid5mvGUzGJ4xRampXXm4PcxZHIqDErO1PKle+XtI89VlvNskOUS
-----END RSA PRIVATE KEY-----
private_key_type    rsa
serial_number       5e:46:d8:74:bf:01:11:f9:b0:70:f3:76:85:91:99:a2:e5:d6:2a:a2
```
Отзовем сертификат:
```shell
[akha@192 kubernetes-vault]$ vault write pki_int/revoke serial_number="5e:46:d8:74:bf:01:11:f9:b0:70:f3:76:85:91:99:a2:e5:d6:2a:a2"
Key                        Value
---                        -----
revocation_time            1704663293
revocation_time_rfc3339    2024-01-07T21:34:53.434414481Z
state                      revoked

```


## PR checklist:
 - [*] Выставлен label с темой домашнего задания