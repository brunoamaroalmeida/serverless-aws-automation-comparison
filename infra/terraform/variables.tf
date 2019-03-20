variable "region" {
  default = "eu-west-1"
}

variable "api_stage_name" {
  default = "dev"
}

variable "website_bucket_name" {
  default = "hello.devopssquad.com"
}

variable "website_bucket_name_log" {
  default = "hello.devopssquad.com"
}
variable "website_bucket_name_log_prefix" {
  default = "logs"
}

variable "deployed_at" {}
