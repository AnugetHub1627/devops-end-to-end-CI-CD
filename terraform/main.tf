provider "aws" {
  region = "ap-south-1"
}

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# ==============================================================================
# 1. NETWORK TOPOLOGY (Multi-AZ VPC for EKS Integration)
# ==============================================================================
resource "aws_vpc" "ci-cd-vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name                                       = var.vpc_name
    "kubernetes.io/cluster/devops-eks-cluster" = "shared"
  }
}

resource "aws_internet_gateway" "ci-cd-gw" {
  vpc_id = aws_vpc.ci-cd-vpc.id

  tags = {
    Name = var.igw_name
  }
}

# Public Subnets (Minimum 2 required across 2 distinct AZs for EKS)
resource "aws_subnet" "ci-cd-pub1a" {
  vpc_id                  = aws_vpc.ci-cd-vpc.id
  cidr_block              = var.subpub1a_cidr
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name                                       = var.subpub1a_name
    "kubernetes.io/cluster/devops-eks-cluster" = "shared"
    "kubernetes.io/role/elb"                   = "1"
  }
}

resource "aws_subnet" "ci-cd-pub1b" {
  vpc_id                  = aws_vpc.ci-cd-vpc.id
  cidr_block              = var.subpub1b_cidr
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true

  tags = {
    Name                                       = var.subpub1b_name
    "kubernetes.io/cluster/devops-eks-cluster" = "shared"
    "kubernetes.io/role/elb"                   = "1"
  }
}

# Private Subnets (Where EKS Nodes safely execute microservice containers)
resource "aws_subnet" "ci-cd-pvt1a" {
  vpc_id            = aws_vpc.ci-cd-vpc.id
  cidr_block        = var.subpvt1a_cidr
  availability_zone = "ap-south-1a"

  tags = {
    Name                                       = var.subpvt1a_name
    "kubernetes.io/cluster/devops-eks-cluster" = "shared"
    "kubernetes.io/role/internal-elb"          = "1"
  }
}

resource "aws_subnet" "ci-cd-pvt1b" {
  vpc_id            = aws_vpc.ci-cd-vpc.id
  cidr_block        = var.subpvt1b_cidr
  availability_zone = "ap-south-1b"

  tags = {
    Name                                       = var.subpvt1b_name
    "kubernetes.io/cluster/devops-eks-cluster" = "shared"
    "kubernetes.io/role/internal-elb"          = "1"
  }
}

# NAT Gateway Infrastructure
resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.ci-cd-pub1a.id

  tags = {
    Name = var.nat_name
  }
}

# Routing Tables and Subnet Associations
resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.ci-cd-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ci-cd-gw.id
  }
}

resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.ci-cd-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

resource "aws_route_table_association" "pub_1a" {
  subnet_id      = aws_subnet.ci-cd-pub1a.id
  route_table_id = aws_route_table.public-rt.id
}

resource "aws_route_table_association" "pub_1b" {
  subnet_id      = aws_subnet.ci-cd-pub1b.id
  route_table_id = aws_route_table.public-rt.id
}

resource "aws_route_table_association" "pvt_1a" {
  subnet_id      = aws_subnet.ci-cd-pvt1a.id
  route_table_id = aws_route_table.private-rt.id
}

resource "aws_route_table_association" "pvt_1b" {
  subnet_id      = aws_subnet.ci-cd-pvt1b.id
  route_table_id = aws_route_table.private-rt.id
}

# ==============================================================================
# 2. STANDALONE SONARQUBE & DOCKER ENGINE SERVER
# ==============================================================================
resource "aws_security_group" "ci-cd_sg" {
  name   = "ci-cd-sg"
  vpc_id = aws_vpc.ci-cd-vpc.id

  # SSH Access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Custom Application Port (e.g., Docker Registry or Jenkins)
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SonarQube Web Interface Portal
  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound Internet Access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ci-cd_host" {
  ami                    = var.cicd_host_ami
  instance_type          = var.ci-cd-ec2-type
  subnet_id              = aws_subnet.ci-cd-pub1a.id
  vpc_security_group_ids = [aws_security_group.ci-cd_sg.id]
  key_name               = var.key_name

  root_block_device {
    volume_size = 25
    volume_type = "gp3"
  }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              sysctl -w vm.max_map_count=524288
              sysctl -w fs.file-max=131072
              echo "vm.max_map_count=524288" >> /etc/sysctl.conf
              echo "fs.file-max=131072" >> /etc/sysctl.conf
              apt-get install -y docker.io
              systemctl start docker
              systemctl enable docker
              docker run -d --name sonarqube -p 9000:9000 -e SONAR_SEARCH_JAVAADDITIONALOPTS="-Dnode.store.allow_mmap=true" --restart always sonarqube:community
              EOF
}

# ==============================================================================
# 3. AMAZON EKS CONTROL PLANE RESOURCES
# ==============================================================================
resource "aws_iam_role" "eks_cluster_role" {
  name = "devops-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_eks_cluster" "ci-cd-EKS" {
  name     = "ci-cd-EKS"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.ci-cd-pub1a.id,
      aws_subnet.ci-cd-pub1b.id,
      aws_subnet.ci-cd-pvt1a.id,
      aws_subnet.ci-cd-pvt1b.id
    ]
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster]
}

# ==============================================================================
# 4. AMAZON EKS MANAGED NODE GROUP
# ==============================================================================
resource "aws_iam_role" "eks_node_role" {
  name = "devops-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_registry" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_eks_node_group" "nodes" {
  cluster_name    = aws_eks_cluster.ci-cd-EKS.name
  node_group_name = "ci-cd-microservice-nodes"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [aws_subnet.ci-cd-pvt1a.id, aws_subnet.ci-cd-pvt1b.id]
  instance_types  = ["t3.micro"]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker,
    aws_iam_role_policy_attachment.eks_cni,
    aws_iam_role_policy_attachment.eks_registry,
  ]
}
