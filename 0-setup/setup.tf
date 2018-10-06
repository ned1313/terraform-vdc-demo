##################################################################################
# VARIABLES
##################################################################################

variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_user_arn" {}
variable "aws_remotestate_bucket" {
    default = "vpcdemo10112018-remotestate"
}

variable "aws_dynamodb_table" {
    default = "vpcdemo10112018-tfstatelock"
}

variable "user_home_path" {}


##################################################################################
# PROVIDERS
##################################################################################

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "us-east-1"
}

##################################################################################
# RESOURCES
##################################################################################
resource "aws_dynamodb_table" "terraform_statelock" {
  name           = "${var.aws_dynamodb_table}"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

resource "aws_s3_bucket" "awsug_remotestate_bucket" {
  bucket = "${var.aws_remotestate_bucket}"
  acl    = "private"
  force_destroy = true
  
  versioning {
    enabled = true
  }

      policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "AWS": "${var.aws_user_arn}"
            },
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::${var.aws_remotestate_bucket}",
                "arn:aws:s3:::${var.aws_remotestate_bucket}/*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_user_policy" "remotestate_rw" {
    name = "remote_state"
    user = "${basename(var.aws_user_arn)}"
    policy= <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::${var.aws_remotestate_bucket}",
                "arn:aws:s3:::${var.aws_remotestate_bucket}/*"
            ]
        },
                {
            "Effect": "Allow",
            "Action": ["dynamodb:*"],
            "Resource": [
                "${aws_dynamodb_table.terraform_statelock.arn}"
            ]
        }
   ]
}
EOF
}

resource "local_file" "aws_keys" {
    content = <<EOF
[default]
aws_access_key_id = ${var.aws_access_key}
aws_secret_access_key = ${var.aws_secret_key}
EOF
    filename = "${var.user_home_path}/.aws/credentials"

}

##################################################################################
# OUTPUT
##################################################################################