provider "aws" {
        region = "eu-west-2"
}

resource "aws_instance" "example" {
    ami = "ami-0fb67ddcbc7557b6e"
    instance_type = "t2.micro"
    user_data =  <<-EOF
                #!/bin/bash
                echo "Hello, Cruel World" > index.html
                nohup busybox httpd -f -p 8080 &
                EOF
    user_data_replace_on_change = true
    key_name = var.key_pair_name
    vpc_security_group_ids = [aws_security_group.web8080.id, aws_security_group.ssh.id]
    tags = {
            Name = "terraform-example1"
    }
}

variable "key_pair_name"{
        description = "key_pair_name"
        type = string
}

variable "file_name" {
    description = "Nme of key pair"
    type = string
}

resource "tls_private_key" "pk"{
    algorithm = "RSA"
    rsa_bits = 4096
}

resource "aws_key_pair" "kp" {
    key_name = var.key_pair_name
    public_key = tls_private_key.pk.public_key_openssh
}

resource "local_sensitive_file" "pk" {
    content = tls_private_key.pk.private_key_pem
    filename = var.file_name
    file_permission = "600"
    directory_permission = "700"
}

resource "aws_security_group" "ssh" {
    name = "terraform-example1-ssh"
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["143.159.210.117/32"]
    }
}

resource "aws_security_group" "web8080" {
    name = "terraform-example1-8080"

    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["143.159.210.117/32"]
    }
}