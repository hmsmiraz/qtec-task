# ─────────────────────────────────────────────────────────────
# EKS Cluster + Managed Node Group
# This is where our K8s workloads will run (Step 8)
# ─────────────────────────────────────────────────────────────

# ── EKS Cluster ───────────────────────────────────────────────
resource "aws_eks_cluster" "main" {
  name     = "${var.project_name}-eks"
  version  = var.eks_cluster_version
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids = concat(
      [for s in aws_subnet.public : s.id],
      [for s in aws_subnet.private : s.id]
    )
    security_group_ids      = [aws_security_group.eks_cluster.id]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  # Enable EKS control plane logging
  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  tags = {
    Name = "${var.project_name}-eks"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
  ]
}

# ── EKS Managed Node Group ────────────────────────────────────
# Worker nodes where our pods will run
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-node-group"
  node_role_arn   = aws_iam_role.eks_node_group.arn

  # Deploy nodes in private subnets (more secure)
  subnet_ids = [for s in aws_subnet.private : s.id]

  # Instance configuration
  instance_types = [var.eks_node_instance_type]
  disk_size      = var.eks_node_disk_size
  ami_type       = "AL2_x86_64"    # Amazon Linux 2

  # Scaling configuration
  scaling_config {
    min_size     = var.eks_node_min_size
    max_size     = var.eks_node_max_size
    desired_size = var.eks_node_desired_size
  }

  # Update configuration for zero-downtime
  update_config {
    max_unavailable = 1    # Only 1 node down at a time during updates
  }

  tags = {
    Name = "${var.project_name}-node-group"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry,
  ]
}