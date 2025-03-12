terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
    }
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

# Create VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "eks-vpc"
  }
}

# Create Internet Gateway (For Public Subnets)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "eks-igw"
  }
}

# Create NAT Gateway (For Private Subnets)
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public[0].id

  depends_on = [aws_internet_gateway.igw]
}

# Create Route Table for Public Subnets
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# Create Route Table for Private Subnets (Uses NAT)
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }
}

# Associate Route Table with Private Subnets
resource "aws_route_table_association" "private" {
  count = 2
  subnet_id = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_rt.id
}

# Associate Public Subnet with Route Table
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public[0].id
  route_table_id = aws_route_table.public_rt.id
}

# Create Private Subnets (For Worker Nodes)
resource "aws_subnet" "private" {
  count             = 2
  vpc_id           = aws_vpc.main.id
  cidr_block       = "10.0.${count.index}.0/24"
  availability_zone = element(["us-east-2a", "us-east-2b"], count.index)

  tags = {
    Name                               = "eks-private-subnet-${count.index}"
    "kubernetes.io/role/internal-elb"  = "1"  # Required for EKS
    "kubernetes.io/cluster/my-eks-cluster" = "owned"  # Required for EKS
  }
}

# Create Public Subnet (For Load Balancers)
resource "aws_subnet" "public" {
  count             = 1
  vpc_id           = aws_vpc.main.id
  cidr_block       = "10.0.10.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name                              = "eks-public-subnet"
    "kubernetes.io/role/elb"          = "1"  # Required for External LB
    "kubernetes.io/cluster/my-eks-cluster" = "owned"  # Required for EKS
  }
}

# Create EKS Cluster (With Only Private Subnets)
resource "aws_eks_cluster" "eks" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_role.arn
  version  = "1.29"

  vpc_config {
    subnet_ids = aws_subnet.private[*].id  # Use only private subnets for EKS security
  }

  depends_on = [aws_iam_role_policy_attachment.eks_role_policy]
}

# Create IAM Role for Worker Nodes
resource "aws_iam_role" "node_role" {
  name = "eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "node_role_policy" {
  role = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "cni_policy" {
  role = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# Create Auto Scaling Group for Worker Nodes
resource "aws_eks_node_group" "node_group" {
  cluster_name = aws_eks_cluster.eks.name
  node_role_arn = aws_iam_role.node_role.arn
  subnet_ids = aws_subnet.private[*].id

  scaling_config {
    desired_size = var.node_count
    min_size = 1
    max_size = 3
  }

  instance_types = [var.node_instance_type]
}