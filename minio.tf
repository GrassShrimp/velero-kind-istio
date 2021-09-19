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
resource "local_file" "minio-ingress" {
  content = <<-EOF
  apiVersion: networking.istio.io/v1alpha3
  kind: Gateway
  metadata:
    name: minio
  spec:
    selector:
      istio: ingressgateway
    servers:
    - port:
        number: 80
        name: http
        protocol: HTTP
      hosts:
      - "minio.pinjyun.local"
  ---
  apiVersion: networking.istio.io/v1alpha3
  kind: VirtualService
  metadata:
    name: minio
  spec:
    hosts:
    - "minio.pinjyun.local"
    gateways:
    - minio
    http:
    - route:
      - destination:
          port:
            number: 9000
          host: minio.minio.svc.cluster.local
  EOF
  filename = "${path.root}/configs/minio-ingress.yaml"
}
resource "null_resource" "minio-ingress" {
  provisioner "local-exec" {
    command = "kubectl apply -f ${local_file.minio-ingress.filename} -n minio"
  }
  depends_on = [
    helm_release.minio
  ]
}