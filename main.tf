resource "aws_instance" "workflow_example" {
    ami = "ami-07c1b39b7b3d2525d"
    instance_type = "t2.micro"
}
