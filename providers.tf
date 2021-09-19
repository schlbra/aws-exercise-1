# Configure the AWS Provider
provider "aws" {
  region     = local.region
  access_key = var.access_key
  secret_key = var.secret_key
}