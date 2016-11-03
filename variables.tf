variable "access_key" {}
variable "secret_key" {}
variable "public_key_path" {}
variable "key_name" {}
variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "us-east-1"
}
