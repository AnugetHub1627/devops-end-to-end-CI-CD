provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

# Safely lookup EKS parameters using the cluster's explicit name string
data "aws_eks_cluster" "cluster" {
  name = "ci-cd-EKS"
}
data "aws_eks_cluster_auth" "cluster" {
  name = "ci-cd-EKS"
}
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
