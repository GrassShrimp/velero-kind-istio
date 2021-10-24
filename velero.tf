resource "helm_release" "velero" {
  name             = "velero"
  repository       = "https://vmware-tanzu.github.io/helm-charts/"
  chart            = "velero"
  version          = var.VELERO_VERSION
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
        region: minio
        s3ForcePathStyle: true
        publicUrl: http://minio.pinjyun.work
        s3Url: http://minio.minio.svc.cluster.local:9000
    defaultVolumesToRestic: true
  credentials:
    name: velero
    secretContents:
      cloud: |
        [default]
        aws_access_key_id=${var.minioAccessKey}
        aws_secret_access_key=${var.minioSecretKey}
  deployRestic: true
  snapshotsEnabled: false
  EOF
  ]
  depends_on = [
    helm_release.minio
  ]
}
