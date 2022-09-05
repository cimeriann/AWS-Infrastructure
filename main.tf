provider "aws" {
    region = "us-east-1"
    profile = "default"
}
resource "aws_instance" "prod-server" {
    ami = "052efd3df9dad4825"
}