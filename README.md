# velero-kind-istio

This is a demo for backup kubernetes via velero

## Prerequisites

- [terraform](https://www.terraform.io/downloads.html)
- [docker](https://www.docker.com/products/docker-desktop)
- [kind](https://kind.sigs.k8s.io/docs/user/quick-start#installation)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [helm](https://helm.sh/docs/intro/install/)
- [velero](https://velero.io/docs/v1.7/basic-install/)

download GCS service account credentials to JSON file names gcs_key.json and put it to .keys at project root path

## Usage

initialize terraform module

```bash
$ terraform init
```

create k8s cluster with kind, and install all components - istio, metallb, minio, mysql

```
$ terraform apply -auto-approve
```

execute backup

```
$ velero backup create mysql-backup --include-namespaces=mysql
```

execute restore

```
$ velero restore create --from-backup=mysql-backup
```

for destroy

```bash
$ terraform destroy -auto-approve
```

![mysql-backup](https://github.com/GrassShrimp/velero-kind-istio/blob/master/mysql-backup.png)