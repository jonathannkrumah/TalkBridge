provider "aws" {
  region = var.region
}

provider "terraform" {
  required_version = ">= 1.0.0"
}