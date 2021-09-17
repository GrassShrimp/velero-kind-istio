resource "null_resource" "download_istio" {
  provisioner "local-exec" {
    command = "curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.11.2 sh -"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -r ${path.module}/istio-1.11.2"
  }

  depends_on = [
    helm_release.metallb
  ]
}

resource "kubernetes_namespace" "istio-operator" {
  metadata {
    annotations = {
      name                             = "istio-operator"
      "meta.helm.sh/release-name"      = "istio-operator"
      "meta.helm.sh/release-namespace" = "istio-operator"
    }

    labels = {
      "app.kubernetes.io/managed-by" = "Helm"
    }

    name = "istio-operator"
  }
  depends_on = [null_resource.download_istio]
}

resource "helm_release" "istio-operator" {
  name            = "istio-operator"
  repository      = "${path.module}/istio-1.11.2/manifests/charts"
  chart           = "istio-operator"
  version         = "1.11.2"
  namespace       = kubernetes_namespace.istio-operator.metadata[0].name
  cleanup_on_fail = true
}

resource "kubernetes_namespace" "istio-system" {
  metadata {
    annotations = {
      name = "istio-system"
    }

    name = "istio-system"
  }
  depends_on = [helm_release.istio-operator]
}

resource "null_resource" "installing-istio" {
  provisioner "local-exec" {
    command = "kubectl apply -f ./istio-profile.yaml -n ${kubernetes_namespace.istio-system.metadata[0].name}"
  }
}
