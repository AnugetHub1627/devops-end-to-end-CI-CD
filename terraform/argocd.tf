# Fetch region details dynamically from your active provider credentials
data "aws_region" "current" {}

# Safely extract your active authentication token directly from the AWS CLI session
data "aws_assume_role_policy" "current" {}
data "aws_client_config" "current" {}

provider "helm" {
  kubernetes = {
    # Dynamically constructs your AWS EKS endpoint string using your region
    host                   = "https://eks.${data.aws_region.current.name}.amazonaws.com"
    cluster_ca_certificate = "" # Keeps the init check safe; AWS CLI overrides this during the final apply
    token                  = data.aws_client_config.current.id
  }
}

# Deploy the Argo CD Helm release
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://github.com/AnugetHub1627/devops-end-to-end-CI-CD.git"
  chart            = "argo-cd"
  version          = "7.3.11"
  namespace        = "argocd"
  create_namespace = true

  set = [
    {
      name  = "server.service.type"
      value = "ClusterIP"
    }
  ]
}
