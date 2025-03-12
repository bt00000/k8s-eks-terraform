variable "aws_region" {
  description = "AWS region"
  type = string
  default = "us-west-2"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type = string
  default = "my-eks-cluster"
}

variable "node_instance_type" {
  description = "EC2 instance type for worker nodes"
  type = string
  default = "t3.medium"
}

variable "node_count" {
  description = "Number of worker nodes"
  type = number
  default = 2
}