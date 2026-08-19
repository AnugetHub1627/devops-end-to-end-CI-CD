provider "helm" {
  # FIXED: Added the equals sign (=) to comply with modern Helm provider syntax rules
  kubernetes = {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

# Hardcoded exact cluster name here so Terraform can look it up in AWS
data "aws_eks_cluster" "cluster" {
  name = "ci-cd-EKS"
}

data "aws_eks_cluster_auth" "cluster" {
  name = "ci-cd-EKS"
}

# Deploy the Argo CD Helm release
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://github.io"
  chart            = "argo-cd"
  version          = "7.3.11"
  namespace        = "argocd"
  create_namespace = true

  set {
    name  = "server.service.type"
    value = "ClusterIP"
  }
}
