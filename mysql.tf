resource "kubernetes_namespace" "mysql" {
  metadata {
    name = "mysql"
  }
  depends_on = [
    helm_release.velero
  ]
}
resource "kubernetes_stateful_set" "mysql" {
  metadata {
    name      = "mysql"
    namespace = kubernetes_namespace.mysql.metadata[0].name
  }
  spec {
    selector {
      match_labels = {
        app = "mysql"
      }
    }
    service_name = "mysql"
    template {
      metadata {
        labels = {
          app = "mysql"
        }
      }
      spec {
        container {
          name              = "mysql"
          image             = "mysql:5.6"
          image_pull_policy = "IfNotPresent"
          port {
            container_port = 3306
            name           = "mysql"
          }
          resources {
            limits = {
              cpu    = "500m"
              memory = "1Gi"
            }
            requests = {
              cpu    = "500m"
              memory = "1Gi"
            }
          }
          readiness_probe {
            exec {
              command = ["mysql", "-h", "127.0.0.1", "-e", "SELECT 1"]
            }
            initial_delay_seconds = 5
            period_seconds        = 2
            timeout_seconds       = 1
          }
          liveness_probe {
            exec {
              command = ["mysqladmin", "ping"]
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
          }
          env {
            name  = "MYSQL_ALLOW_EMPTY_PASSWORD"
            value = "1"
          }
          volume_mount {
            name       = "data"
            mount_path = "/var/lib/mysql"
          }
        }
      }
    }
    volume_claim_template {
      metadata {
        name = "data"
      }
      spec {
        access_modes = ["ReadWriteOnce"]
        resources {
          requests = {
            storage = "10Gi"
          }
        }
        storage_class_name = "standard"
      }
    }
  }
}
resource "kubernetes_service" "mysql" {
  metadata {
    name      = "mysql"
    namespace = kubernetes_namespace.mysql.metadata[0].name
  }
  spec {
    selector = kubernetes_stateful_set.mysql.spec[0].selector[0].match_labels
    port {
      port        = 3306
      target_port = 3306
    }
    type = "ClusterIP"
  }
}
