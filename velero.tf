resource "helm_release" "velero" {
  name             = "velero"
  repository       = "https://vmware-tanzu.github.io/helm-charts/"
  chart            = "velero"
  version          = "2.23.8"
  namespace        = "velero"
  create_namespace = true
  values = [
    <<-EOF
  initContainers:
  - name: velero-plugin-for-aws
    image: velero/velero-plugin-for-aws:v1.2.1
    volumeMounts:
    - mountPath: /target
      name: plugins
  configuration:
    provider: aws
    backupStorageLocation:
      bucket: velero-${random_uuid.minio.result}
      config:
        region: default
        s3ForcePathStyle: true
        publicUrl: http://minio.pinjyun.local
        s3Url: http://minio.minio.svc.cluster.local:9000
    volumeSnapshotLocation:
      config:
        region: default
  credentials:
    name: velero
    secretContents:
      cloud: |
        [default]
        aws_access_key_id=${var.minioAccessKey}
        aws_secret_access_key=${var.minioSecretKey}
  EOF
  ]
  depends_on = [
    helm_release.minio
  ]
}
