provider "helm" {
  kubernetes = {
    # FIXED: Replaced data block paths with direct resource dependencies
    host                   = aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}


# Hardcoded exact cluster name here so Terraform can look it up in AWS
data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.this.name
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
