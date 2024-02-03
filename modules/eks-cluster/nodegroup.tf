#
# EKS Worker Nodes Resources
#  * IAM role allowing Kubernetes actions to access other AWS services
#  * EKS Node Group to launch worker nodes
# creates launch template and ASG and launches worker nodes into it
resource "aws_launch_template" "app_nodegroup_launch_template" {
  name = "${var.eks_cluster_name}_app_nodegroup_launch_template"
  tags = merge(var.tags, { Name = "${var.eks_cluster_name}-app-node-group" })
  instance_type = var.instance_type
  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, { Name = "${var.eks_cluster_name}-app-node-group" })
  }
}

resource "aws_eks_node_group" "app-nodegroup" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.eks_cluster_name}-app-node-group"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.subnet_ids
  labels = {"Nodegroup" = "app-nodegroup"}
  launch_template {
    id = aws_launch_template.app_nodegroup_launch_template.id
    version = aws_launch_template.app_nodegroup_launch_template.latest_version
    }
  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }  
  tags = merge(var.tags, { Name = "${var.eks_cluster_name}-app-node-group" })
}

resource "aws_autoscaling_group_tag" "app-nodegroup-tag" {
  for_each = merge(var.tags, { Name = "${var.eks_cluster_name}-app-node-group" })
  autoscaling_group_name = aws_eks_node_group.app-nodegroup.resources[0].autoscaling_groups[0].name
  tag {
    key   = each.key
    value =  each.value
    propagate_at_launch = true
  }
}
