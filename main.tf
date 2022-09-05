provider "aws" {
    region = "us-east-1"
    profile = "default"
}

resource "aws_vpc" "prod-vpc" {
    cidr_block = "10.0.0.0/16"
    tags = {
      Name = "prod-vpc"
    }
}

resource "aws_subnet" "subnet-1" {
  cidr_block = "10.0.1.0/24"
  vpc_id = aws_vpc.prod-vpc.id
}
resource "aws_instance" "prod-server" {
    instance_type = "t2.micro"
    ami = "052efd3df9dad4825"
    vpc_security_group_ids = ["sg-12345678"]
    subnet_id              = "subnet-eddcdzz4"   

    tags = {
      Name = "prod-server"
    }
}