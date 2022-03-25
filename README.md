# CARTO self-hosted [Helm chart]

This repository contains the [Kubernetes Helm](https://github.com/helm/helm) chart files for CARTO Platform. Run CARTO Self Hosted in your own cloud infrastructre.

If you are looking for another installation method, please refer to [carto-selfhosted repository](https://github.com/CartoDB/carto-selfhosted).

## Installation

### Prerequisites

- Kubernetes 1.12+
- Helm 3.1.0
- (Optional) PV provisioner support in the underlying infrastructure. Required only for non-production deployment without external and managed databases (Postgres and Redis).

<!--
Currently the only Kubernetes that have been tested are EKS, GKE and AKS.
-->

#### Setup a Kubernetes Cluster

For setting up Kubernetes on other cloud platforms or bare-metal servers refer to the Kubernetes [getting started guide](http://kubernetes.io/docs/getting-started-guides/).

#### Install Helm

Helm is a tool for managing Kubernetes charts. Charts are packages of pre-configured Kubernetes resources.

To install Helm, refer to the [Helm install guide](https://github.com/helm/helm#install) and ensure that the `helm` binary is in the `PATH` of your shell.

### Installation Steps

1. Authenticate and connect to your cluster

2. Obtain the configuration files provided by Carto.
That files are unique per self-hosted (**they cannot be shared between multiple installations**) and contain secrets, be careful storing and sharing them.

3. Add CARTO helm repository:

  ```bash
  # Add the carto repo.
  helm repo add carto https://helm.carto.com

  # Retrieve the latests version of the packages. REQUIRED before update to a new version.
  helm repo update

  # List the available versions of the package
  helm search repo carto -l
  ```

4. Configure your deployment. Please, read the available [configuration](customizations/README.md) options. At least you need 
to configure your domain.

5. Install CARTO:

  ```bash
  helm install \
    <your_own_installation_name|carto> \
    carto/carto \
    --namespace <your_namespace> \
    -f carto-values.yaml \
    -f carto-secrets.yaml \
    -f customization.yaml
  ```

  > Note: You can specify the '-f' flag multiple times. The priority will be given to the last (right-most) file specified. For example, if both `carto-values.yaml` and `client-conf.yaml` contained a key called 'Test', the value set in `client-conf.yaml` would take precedence. For this reason, please follow the order describe in the above example.

6. Read and follow the instructions provided by the previous command.

## Update

1. Authenticate and connect to your cluster

2. Update the helm chart:

  ```bash
  helm repo update
  ```

3. Update CARTO

  ```bash
  helm upgrade \
    <your_own_installation_name|carto> \
    carto/carto \
    --namespace <your_namespace> \
    -f carto-values.yaml \
    -f carto-secrets.yaml \
    -f customization.yaml
  ```

## Unistallation

To remove CARTO from your cluster you need to run:

```bash
helm uninstall <your_own_installation_name|carto> --wait
```

If you were using the internal Postgres, to delete the data you need:

```bash
# ⚠️ This is going to delete the data of the postgres inside the cluster ⚠️
kubectl delete pvc data-<your_own_installation_name|carto>-postgresql-0
```
