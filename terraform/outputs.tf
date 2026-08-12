output "instance_public_ip" {
  description = "Public IP address of the deployed EC2 server"
  value       = aws_instance.ci-cd_host.public_ip
}
output "sonarqube_server_ip" {
  value = aws_instance.ci-cd_host.public_ip
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.ci-cd-EKS.endpoint
}

