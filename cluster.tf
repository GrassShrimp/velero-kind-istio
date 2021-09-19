resource "kind_cluster" "k8s-cluster" {
  name   = "k8s-cluster"
  image  = "kindest/node:v1.22.1"
  config = <<-EOF
    kind: Cluster
    apiVersion: kind.x-k8s.io/v1alpha4
    nodes:
    - role: control-plane
      kubeadmConfigPatches:
      - |
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true"
      extraPortMappings:
      - containerPort: 32041
        hostPort: 80
        protocol: TCP
      - containerPort: 31236
        hostPort: 443
        protocol: TCP
    - role: worker
      extraMounts:
      - hostPath: /tmp/mnt_worker1/
        containerPath: /mnt/disks
    - role: worker
      extraMounts:
      - hostPath: /tmp/mnt_worker2/
        containerPath: /mnt/disks
  EOF
}
