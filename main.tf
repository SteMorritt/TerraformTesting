provider "aws" {
        region = "eu-west-2"
}

variable "cidraddresses" {
    description = "List containing CIDR addresses for firewall rules"
    type = list(string)
    default = ["143.159.210.117/32","213.143.146.149/32"]
}

data "aws_vpc" "default" {
    default = true
}

data "aws_subnets" "default"{
    filter {    
        name = "vpc-id"
        values = [data.aws_vpc.default.id]
    }
}

resource "aws_launch_configuration" "example" {
    image_id = "ami-07c1b39b7b3d2525d"
    instance_type = "t2.micro"
    security_groups = [aws_security_group.web8080.id]
    user_data =  <<-EOF
                #!/bin/bash
                echo "Hello, Cruel World" > index.html
                nohup busybox httpd -f -p 8080 &
                EOF
    #user_data_replace_on_change = true
    key_name = var.key_pair_name
    #vpc_security_group_ids = [aws_security_group.web8080.id, aws_security_group.ssh.id, aws_security_group.defaultOUT.id]
    #tags = {
    #        Name = "terraform-example1"
    #}
    lifecycle {
      create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "example" {
    launch_configuration = aws_launch_configuration.example.name
    min_size = 2
    max_size = 10
    tag { 
        key = "Name"
        value = "terraform-asg-example"
        propagate_at_launch = true

    }
    vpc_zone_identifier = data.aws_subnets.default.ids
    
    target_group_arns = [aws_lb_target_group.asg.arn]
    health_check_type = "ELB"
    
}

resource "aws_lb_listener_rule" "asg"{
    listener_arn = aws_lb_listener.http.arn
    priority = 100
    condition {
      path_pattern {
        values = ["*"]
      }
    }
    action {
      type = "forward"
      target_group_arn = aws_lb_target_group.asg.arn
    }
}

resource "aws_lb" "example" {
    name = "terraform-asg-example"
    load_balancer_type = "application"
    subnets = data.aws_subnets.default.ids

    security_groups = [aws_security_group.defaultOUT.id,aws_security_group.web80.id]
}

resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.example.arn
    port = 80
    protocol = "HTTP"
    default_action{
        type= "fixed-response"
        fixed_response {
          content_type = "text/plain"
          message_body = "404: Page Not Found"
          status_code = 404
        }
    }
}

resource "aws_lb_target_group" "asg"{
    name = "terraform-asg-example"
    port = "8080"
    protocol = "HTTP"
    vpc_id = data.aws_vpc.default.id

    health_check {
      path ="/"
      protocol = "HTTP"
      matcher = 200
      interval = 15
      timeout = 3
      healthy_threshold = 2
      unhealthy_threshold = 2
    }
}

variable "key_pair_name"{
        description = "key_pair_name"
        type = string
        default = "testpair1"
}

variable "file_name" {
    description = "Name of key pair"
    type = string
    default="testpair"
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
        cidr_blocks = var.cidraddresses
    }
}

resource "aws_security_group" "defaultOUT"{
    name = "terraform-example1-defaultOUT"

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]

    }
}

resource "aws_security_group" "web8080" {
    name = "terraform-example1-8080"

    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "web80" {
    name = "terraform-example1-80"

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = var.cidraddresses
    }
}

output "alb_dns_name"{
    value = aws_lb.example.dns_name
    description = "The domain name of the load balancer"
}