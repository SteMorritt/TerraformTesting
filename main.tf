provider "aws" {
        region = "eu-west-2"
}

terraform {
    backend "s3" {
        bucket = "morritts-terraform-up-and-running-state"
        key = "global/S3/terraform.tfstate"
        region ="eu-west-2"
        dynamodb_table = "terraform-up-and-running-locks"
        encrypt = true
    }
}

