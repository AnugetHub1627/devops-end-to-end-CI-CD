variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "vpc_name" {
  type    = string
  default = "ci-cd-vpc"
}

variable "igw_name" {
  type    = string
  default = "ci-cd-igw"
}

variable "subpub1a_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "subpub1a_name" {
  type    = string
  default = "ci-cd-pub1a"
}

variable "subpub1b_cidr" {
  type    = string
  default = "10.0.2.0/24"
}

variable "subpub1b_name" {
  type    = string
  default = "ci-cd-pub1b"
}

variable "subpvt1a_cidr" {
  type    = string
  default = "10.0.3.0/24"
}

variable "subpvt1a_name" {
  type    = string
  default = "ci-cd-pvt1a"
}

variable "subpvt1b_cidr" {
  type    = string
  default = "10.0.4.0/24"
}

variable "subpvt1b_name" {
  type    = string
  default = "ci-cd-pvt1b"
}

variable "nat_name" {
  type    = string
  default = "ci-cd-nat"
}

variable "cicd_host_ami" {
  type    = string
  default = "ami-01a00762f46d584a1"
}

variable "cicd_ec2_type" {
  type    = string
  default = "m7i-flex.large"
}

variable "key_name" {
  type    = string
  default = "key_mukesh"
}


