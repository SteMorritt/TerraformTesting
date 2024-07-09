provider "aws" {
        region = "eu-west-2"
}

resource "aws_instance" "example" {
    ami = "ami-0fb67ddcbc7557b6e"
    instance_type = "t2.micro"

    tags = {
            Name = "terraform-example1"
    }
}