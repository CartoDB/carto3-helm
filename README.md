# Helm chart and Docker compose for Carto 3

This repository contains the Helm chart files for Carto 3, ready to launch on Kubernetes using [Kubernetes Helm](https://github.com/helm/helm).

## Deploy CARTO in a self hosted environment

- Create new SelfHosted environment in [carto3-onprem-customers](https://github.com/CartoDB/carto3-onprem-customers)

- Download customer package files, they will be placed in the package folder

```bash
./tools/download_k8s_secrets.sh customers/YOUR-CUSTOMER-ID
```

- Create the service account secret inside kubernetes
```bash
kubectl apply -f k8s-google-serviceaccount-secret.yaml --namespace=<namespace>
```

- Add Carto repository to helm:

```bash
helm repo add carto-selfhosted-charts https://carto-selfhosted-charts.storage.googleapis.com
```

- Check the repositories:

```bash
helm repo list
NAME                    URL                                                   
carto-selfhosted-charts https://carto-selfhosted-charts.storage.googleapis.com

helm search repo carto-selfhosted-charts -l
NAME                          CHART VERSION APP VERSION   DESCRIPTION                                       
carto-selfhosted-charts/carto 1.6.6         2022.03.07.03 CARTO is the world's leading Location Intellige...
carto-selfhosted-charts/carto 1.5.5         2022.03.04.06 CARTO is the world's leading Location Intellige...
carto-selfhosted-charts/carto 1.3.14        2022.02.10    CARTO is the world's leading Location Intellige...
```

- Update repository if you have new chart versions
```bash
helm repo update
```

- Install Carto SelfHosted
```bash
helm install carto-selfhosted-v1 carto-selfhosted-charts/carto -f carto-values.yaml -f carto-secrets.yaml
```

- Add the Kubernetes Load Balancer IP to your DNS with your Domain:

  In GKE:
  ```bash
  kubectl get svc <carto-selfhosted-v1>-router -o jsonpath='{.status.loadBalancer.ingress.*.ip}'
  ```
  
  In EKS:
  ```bash
  nslookup $(kubectl get svc <carto-selfhosted-v1>-router -o jsonpath='{.status.loadBalancer.ingress.*.hostname}')
  ```

### Custom Domain

By default, the carto router deployment will create its own auto generate ssl certs, but if your want to install carto selfhosted with your custom domain and TLS certs, you have to do the following steps:
  
- Change the `routerSslAutogenerate` value to `"1"` in `carto-values.yaml`

- Create a kubernetes secret with following content:
  ```yaml
  apiVersion: v1
  kind: Secret
  metadata:
    name: <kubernetes-tls-secret-name>
  type: Opaque
  data:
    tls.key: "<base64 encoded key>"
    tls.crt: "<base64 encoded certificate>"
    ca.crt: "<base64 encoded public ca file>"
  ```
  Note that the content of certs should be formatted in base64 in one line, e.g:
  ```bash
  cat certificate.crt | base64 -w0
  ```
- Then create the object in kubernetes with `kubectl apply -f <secret-tls-file> -n <namespace>`

- Finally, you have to add the following lines to `carto-secrets.yaml`:
  ```yaml
  tlsCerts:
    autoGenerate: false
    existingSecret:
      name: "<kubernetes-tls-secret-name>"
      caKey: "ca.crt"
      keyKey: "tls.key"
      certKey: "tls.crt"
  ```


### External Postgres

By default, Carto-Selfhosted is provisioned with a Postgresl statefulset kubernetes object, but you could connect this environment with your own Cloud Postgres instance, follow this steps to make it possible:

- Add these lines in your `carto-values.yaml`, you can find it and uncomment inside the file:

  ```yaml
  postgresql:
    enabled: false
  ```

- Create one secret in kubernetes with the Postgres passwords:

  ```bash
  kubectl create secret generic <my-external-postgres-secret-name> --from-literal=carto-password=<password> --from-literal=admin-password=<password>

  ```

- Add the postgres IP/hostname and the secret reference in these lines, you can find this configuration inside `carto-secrets.yaml`:

  ```yaml
  externalDatabase:
    host: <Postgres IP/Hostname>
    user: carto
    password: ""
    adminUser: postgres
    adminPassword: ""
    existingSecret: "<kubernetes postgres created secret name>"
    existingSecretPasswordKey: "carto-password"
    existingSecretAdminPasswordKey: "admin-password"
    database: workspace_db
    port: 5432
  ```

- Note: `carto` user and `workspace_db` database inside the Postgres instance are going to be created automatically during the installation process, they do not need to be pre-created. The `carto-password` indicated in the kubernetes secret created before is with which this user will be created

### External Redis

By default, Carto-Selfhosted is provisioned with a Redis statefulset kubernetes object, but you could connect this environment with your own Cloud Redis instance, follow this steps to make it possible:

- Add these lines in your `carto-values.yaml`, you can find it and uncomment inside the file:

  ```yaml
  redis:
    enabled: false
  ```

- Create one secret in kubernetes with the Redis AUTH string:

  ```bash
  kubectl create secret generic <my-external-redis-secret-name> --from-literal=password=<AUTH string password>
  ```

- Add the Redis IP/hostname and the secret reference in these lines, you can find this configuration inside `carto-secrets.yaml`:

  ```yaml
  externalRedis:
    host: <Redis IP/Hostname>
    port: 6379
    password: ""
    existingSecret: "<kubernetes redis created secret name>"
    existingSecretPasswordKey: "password"
  ```

## Before you begin

### Prerequisites

- Kubernetes 1.12+
- Helm 3.1.0
- PV provisioner support in the underlying infrastructure

### Setup a Kubernetes Cluster

For setting up Kubernetes on other cloud platforms or bare-metal servers refer to the Kubernetes [getting started guide](http://kubernetes.io/docs/getting-started-guides/).

### Install Docker

Docker is an open source containerization technology for building and containerizing your applications.

To install Docker, refer to the [Docker install guide](https://docs.docker.com/engine/install/).

### Install Helm

Helm is a tool for managing Kubernetes charts. Charts are packages of pre-configured Kubernetes resources.

To install Helm, refer to the [Helm install guide](https://github.com/helm/helm#install) and ensure that the `helm` binary is in the `PATH` of your shell.

