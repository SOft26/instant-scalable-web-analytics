variable "region" {
  default = "us-east-1"   # change to your preferred AWS region
}

variable "cluster_name" {
  default = "plausible-eks"
}

variable "node_instance_type" {
  default = "t3.medium"   # small, cheap instance
}

variable "desired_capacity" {
  default = 1
}
