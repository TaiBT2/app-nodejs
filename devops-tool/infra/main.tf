provider "aws" {
  region = "us-east-1"
}

data "aws_ami" "ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  owners = ["099720109477"]
}


resource "aws_instance" "server" {
  ami           = data.aws_ami.ami.id
  instance_type = "t3.micro"
  key_name      = "bttai"
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    project = "${var.name_project}"
  }
}

output "ec2" {
  value = aws_instance.server.public_ip
}