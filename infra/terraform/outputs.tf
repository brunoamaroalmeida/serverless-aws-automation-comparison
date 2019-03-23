output "s3_website_url" {
  value = "${aws_s3_bucket.website_bucket.website_endpoint}"
}

#output "api_invoke_url" {
#  value = "${aws_api_gateway_deployment.instance.invoke_url}/${aws_api_gateway_resource.resource.path_part}"
#}
