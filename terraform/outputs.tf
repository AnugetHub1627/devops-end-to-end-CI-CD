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
# 4. Output the completed string to copy into your repository secrets
output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions_role.arn
  description = "Copy this literal string into your GitHub AWS_ROLE_TO_ASSUME secret repository slot!"
}


