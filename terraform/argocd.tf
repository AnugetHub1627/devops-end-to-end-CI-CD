provider "helm" {
  kubernetes = {
    # FIXED: Links directly to your actual resource block named "eks"
    host                   = aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

# Fetches the authentication token for your cluster name
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

  # Tells Helm to wait until the EKS cluster resource is completely active
  depends_on = [aws_eks_cluster.eks]

  set = [
    {
      name  = "server.service.type"
      value = "ClusterIP"
    }
  ]
}
