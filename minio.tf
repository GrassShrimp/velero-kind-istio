resource "random_uuid" "minio" {
}

resource "helm_release" "minio" {
  name             = "minio"
  repository       = "https://helm.min.io/"
  chart            = "minio"
  version          = "8.0.10"
  namespace        = "minio"
  create_namespace = true
  values = [
    <<-EOF
  accessKey: "${var.minioAccessKey}"
  secretKey: "${var.minioSecretKey}"
  defaultBucket:
    enabled: true
    name: velero-${random_uuid.minio.result}
  gcsgateway:
    enabled: true
    replicas: 1
    gcsKeyJson: '${replace(file("${path.root}/.keys/pinjyun-8d9c080ae4d3.json"), "\n", "")}'
    projectId: "pinjyun"
  persistence:
    enabled: false
  EOF
  ]
  depends_on = [
    null_resource.installing-istio
  ]
}
resource "null_resource" "minio-ingress" {
  provisioner "local-exec" {
    command = "kubectl apply -f ${path.root}/configs/minio-ingress.yaml -n minio"
  }
  provisioner "local-exec" {
    when = destroy
    command = "kubectl delete -f ${path.root}/configs/minio-ingress.yaml -n minio"
  }
  depends_on = [
    helm_release.minio
  ]
}