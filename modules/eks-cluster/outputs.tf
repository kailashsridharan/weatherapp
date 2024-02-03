output "cluster_name" {
  value       = aws_eks_cluster.this.name
  description = "Cluster name provided when the cluster was created."
}

output "cluster_status" {
  value       = aws_eks_cluster.this.status
  description = "Cluster name provided when the cluster was created."
}

output "cluster_endpoint" {
  value       = aws_eks_cluster.this.endpoint
  description = "Endpoint of the Kubernetes Control Plane."
  #sensitive = true
}

output "cluster_authentication_token" {
  value       = data.aws_eks_cluster_auth.this.token
  description = "token used to authenticate with eks cluster"
  #sensitive = true
}

output "cluster_auth_certificate" {
  value       = aws_eks_cluster.this.certificate_authority[0].data
  description = "Certificate used to authenticate to the Kubernetes Controle Plane."
  #sensitive = true
}

output "cluster_role" {
  value       = aws_iam_role.cluster.name
  description = "IAM Role which has the required policies to add the node to the cluster."
}

output "cluster_role_arn" {
  value       = aws_iam_role.cluster.arn
  description = "IAM Role ARN which has the required policies to add the node to the cluster."
}

output "cluster_security_group" {
  value       = aws_security_group.this.id
  description = "Security Group between cluster and nodes."
}

output "cluster_oidc_provider" {
  value = aws_eks_cluster.this.identity[0].oidc[0].issuer
  #sensitive = true
}

output "aws_iam_openid_connect_provider_url" {
  value = aws_iam_openid_connect_provider.openid_connect.url
}

output "aws_iam_openid_connect_provider_arn" {
  value = aws_iam_openid_connect_provider.openid_connect.arn
}

output "node_role" {
  value       = aws_iam_role.node.name
  description = "IAM Role which has the required policies to add the node to the cluster."
}

output "node_iam_role_arn" {
  value       = aws_iam_role.node.arn
  description = "IAM Role ARN which has the required policies to add the node to the cluster."
}

