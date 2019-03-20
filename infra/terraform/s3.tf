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

  //  logging {
  //    target_bucket = "${var.website_bucket_name_log}"
  //    target_prefix = "${var.website_bucket_name_log_prefix}"
  //  }

  ##tags = "${merge("${var.tags}",map("Name", "${var.project}-${var.environment}-${var.domain}", "Environment", "${var.environment}", "Project", "${var.project}"))}"
}
