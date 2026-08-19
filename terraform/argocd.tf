provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.cluster.endpoint
    # FIXED: Added [0] index accessor to extract the data key out of the object list block
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
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
