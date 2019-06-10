# Configure the AWS Provider
provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
  profile = "me"
}

module "s3_website_www" {
  source         = "git::https://github.com/cloudposse/terraform-aws-s3-website.git?ref=0.7.0"
  namespace      = "locksmithatlanta"
  stage          = "prod"
  name           = "www.locksmithatlanta.com"
  hostname       = "www.locksmithatlanta.com"
}


module "s3_website" {
  source         = "git::https://github.com/cloudposse/terraform-aws-s3-website.git?ref=0.7.0"
  namespace      = "locksmithatlanta"
  stage          = "prod"
  name           = "locksmithatlanta.com"
  hostname       = "locksmithatlanta.com"
  redirect_all_requests_to = "www.locksmithatlanta.com"
}


module "cdn_no_s3_www" {
  source             = "git::https://github.com/cloudposse/terraform-aws-cloudfront-cdn.git?ref=0.7.0"
  namespace          = "locksmithatlanta"
  stage              = "prod"
  name               = "locksmithatlanta.com"
  aliases            = ["www.locksmithatlanta.com"]
  parent_zone_id = "${var.zone_id}"
  origin_protocol_policy = "http-only"
  viewer_protocol_policy = "redirect-to-https"
  viewer_minimum_protocol_version = "TLSv1.2_2018"
  acm_certificate_arn = "${var.cert_arn}"
  origin_domain_name = "${module.s3_website_www.s3_bucket_website_endpoint}"
  compress = true
  custom_error_response = [
    {
        "error_code"          = 404
        "response_code"       = 200
        "response_page_path"  = "/404.html"
        }
    ]
}

module "cdn_no_s3" {
  source             = "git::https://github.com/cloudposse/terraform-aws-cloudfront-cdn.git?ref=0.7.0"
  namespace          = "locksmithatlanta"
  stage              = "prod"
  name               = "locksmithatlanta.com"
  aliases            = ["locksmithatlanta.com"]
  parent_zone_id = "${var.zone_id}"
  origin_protocol_policy = "http-only"
  viewer_minimum_protocol_version = "TLSv1.2_2018"
  acm_certificate_arn = "${var.cert_arn}"
  origin_domain_name = "${module.s3_website.s3_bucket_website_endpoint}"
}

resource "null_resource" "remove_and_upload_to_s3" {
  provisioner "local-exec" {
    command = "aws s3 sync ../_site/ s3://www.locksmithatlanta.com"
  }
}