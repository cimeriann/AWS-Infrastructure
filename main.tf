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

resource "aws_route_table" "prod-rt" {
    vpc_id = aws_vpc.prod-vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.prod-igw.id
    }

    route {
        cidr_block = "::/0"
        gateway_id = aws_internet_gateway.prod-igw.id
    }
}

resource "aws_internet_gateway" "prod-igw" {
    vpc_id = aws_vpc.prod-vpc.id
    tags = {
      Name = "igw"
    }
}

resource "aws_security_group" "allow_web" {
    name = "allow_webtraffic"
    description = "allows web inbound traffic"
    vpc_id = aws_vpc.prod-vpc.id

    ingress {
        description = "https"
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "http"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        description = "allow ssh"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_subnet" "subnet-1" {
  cidr_block = "10.0.1.0/24"
  vpc_id = aws_vpc.prod-vpc.id
  availability_zone = "us-east-1a"

  tags = {
    Name = "prod-subnet"
  }
}

resource "aws_route_table_association" "rta" {
    subnet_id = aws_subnet.subnet-1.id
    route_table_id = aws_route_table.prod-rt.id
}

resource "aws_network_interface" "web-server-nic" {
    subnet_id = aws_subnet.subnet-1.id
    private_ip = "10.0.1.50"
    security_groups = [ aws_security_group.allow_web.id ]
}

resource "aws_eip" "prod-eip" {
    vpc = true
    network_interface = aws_network_interface.web-server-nic.id
    associate_with_private_ip = "10.0.1.50"
    depends_on = [
      aws_internet_gateway.prod-igw
    ]

}
resource "aws_instance" "prod-server" {
    instance_type = "t2.micro"
    ami = "052efd3df9dad4825"
    availability_zone = "us-east-1a"
    key_name = "terraform-kp"

    network_interface {
        device_index = 0
        network_interface_id = aws_network_interface.web-server-nic.id
    }
    user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c echo "my very first webserver" > /var/www/html/index.html
                EOF

    tags = {
      Name = "prod-server"
    }
}