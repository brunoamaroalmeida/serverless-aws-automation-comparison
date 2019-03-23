#https://github.com/ringods/terraform-website-s3-cloudfront-route53/blob/master/site-main/variables.tf

data "template_file" "bucket_policy" {
  template = "${file("${path.module}/website_policy.json")}"

  vars {
    bucket = "${var.website_bucket_name}"
  }
}

resource "aws_s3_bucket" "website_bucket" {
  bucket   = "${var.website_bucket_name}"
  policy   = "${data.template_file.bucket_policy.rendered}"

  website {
    index_document = "index.html"
    error_document = "404.html"
    routing_rules  = ""
  }
  cors_rule {
     allowed_headers = ["*"]
     allowed_methods = ["PUT", "POST"]
     allowed_origins = ["*"]
     expose_headers  = ["ETag"]
     max_age_seconds = 3000
   }
}

data "aws_route53_zone" "default" {
  name    = "${var.parent_zone_name}"
}

resource "aws_route53_record" "default" {
  zone_id = "${data.aws_route53_zone.default.zone_id}"
  name    = "${var.domain}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${aws_s3_bucket.website_bucket.website_endpoint}"]
}
