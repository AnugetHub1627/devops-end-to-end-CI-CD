provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.cluster.endpoint
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
  repository       = "https://github.com/AnugetHub1627/devops-end-to-end-CI-CD.git"
  chart            = "argo-cd"
  version          = "7.3.11"
  namespace        = "argocd"
  create_namespace = true

  depends_on = [
    data.aws_eks_cluster.cluster,
    data.aws_eks_cluster_auth.cluster
  ]
  set = [
    {
      name  = "server.service.type"
      value = "ClusterIP"
    }
  ]
}
