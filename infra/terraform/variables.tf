variable "region" {
  default = "eu-west-1"
}

variable "api_stage_name" {
  default = "dev"
}

variable "website_bucket_name" {
  default = "hello.devopssquad.com"
}

variable "results_bucket_name" {
  default = "devopssquad-results"
}

variable "deployed_at" {}

variable domain {
  default = "hello.devopssquad.com"
}

variable api_domain{
  default = "api.devopssquad.com"
}

variable regional_acm_arm{
  default = "arn:aws:acm:eu-west-1:831363121910:certificate/642953bd-7ac9-4249-b5e2-249ceb571e2c"
}

variable "parent_zone_name" {
  default = "devopssquad.com"
}
