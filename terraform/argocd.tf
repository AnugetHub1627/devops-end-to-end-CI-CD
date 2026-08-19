provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

# Clean data blocks without nested resource parameters
data "aws_eks_cluster" "cluster" {
  name = "ci-cd-EKS"
}

data "aws_eks_cluster_auth" "cluster" {
  name = "ci-cd-EKS"
}

# The parameters belong strictly inside the resource block below
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://github.com/AnugetHub1627/devops-end-to-end-CI-CD.git"
  chart            = "argo-cd"
  version          = "7.3.11"
  namespace        = "argocd"
  create_namespace = true

  # Resource wait condition
  depends_on = [
    data.aws_eks_cluster.cluster,
    data.aws_eks_cluster_auth.cluster
  ]

  # Configuration array maps
  set = [
    {
      name  = "server.service.type"
      value = "ClusterIP"
    }
  ]
}
