terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
    }
    required_version = ">= 1.3.0"
  }
}

provider "aws" {
  region = var.aws_region
}

# Create IAM Role for EKS
resource "aws_iam_role" "eks_role" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_role_policy" {
  role = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Create EKS Cluster
resource "aws_eks_cluster" "eks" {
  name = var.cluster_name
  role_arn = aws_iam_role.eks_role.arn
  version = "1.29"

  vpc_config {
    subnet_ids = aws_subnet.private[*].subnet_ids
  }

  depends_on = [ aws_iam_role_policy_attachment.eks_role_policy ]
}