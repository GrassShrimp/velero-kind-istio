resource "random_uuid" "minio" {
}
resource "kubernetes_persistent_volume" "minio" {
  metadata {
    name = "minio"
  }
  spec {
    capacity = {
      storage = "10Gi"
    }
    access_modes = ["ReadWriteOnce"]
    persistent_volume_source {
      local {
        path = "/mnt/disks/minio"
      }
    }
    storage_class_name = "standard"
    node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key = "kubernetes.io/hostname"
            operator = "NotIn"
            values = ["k8s-cluster-control-plane"]
          }
        }
      }
    }
    persistent_volume_reclaim_policy = "Delete"
  }
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
    gcsKeyJson: '${replace(file("${path.root}/.keys/gcs_key.json"), "\n", "")}'
    projectId: "pinjyun"
  persistence:
    enabled: true
    VolumeName: ${kubernetes_persistent_volume.minio.metadata[0].name}
    size: 10Gi
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