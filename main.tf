locals {
  availability_zone  = "${local.region}a"
  region             = "us-west-2"
  all_ipv4_addresses = "0.0.0.0/0"
  tags = {
    Owner       = "brad"
    Environment = "dev"
  }
}

variable "access_key" {}

variable "secret_key" {}

################################################################################
# Supporting Resources
################################################################################

resource "aws_key_pair" "deployer" {
  key_name   = "deployer"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCZY41hHNGVMA6HOXgCTCHFOjzMTLHycRAX/md5AQwyn4Y4d2+5spmyWKB90fkF8eloxn22t1R9OjqcH3uO6vOy3nw/jCitvQLtS3frNwAprF0ez78xSDMSoG9bmhU9UfT0SOwelT2J+0AQZ0MNSiqjFZK7TeMgVpRHyVdUqhgULd0kIlzDAUGJAYDfQHTW3nctQeMnjIh8HiPaf+N+n1FcHN4/NdlyjrGqZk4+hQtdVDWLnK4SUpJmiyzIQCG0KII7n7LEBEZszLmvrt5NPIu2tZHN1LWYF9ANXrnYEVyQsKQ5GVg4qsumhg3uXHUvM4VGLUYHcJxPp4FeRHkv298D"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = local.tags
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = local.tags
}

resource "aws_subnet" "main" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = local.availability_zone
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = local.tags
}

resource "aws_route" "default" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "sg" {
  name        = "exercise-1-sg"
  description = "Allow  traffic for HTTP and SSH"
  vpc_id      = aws_vpc.main.id

  # Allow Inbound HTTP Traffic
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [local.all_ipv4_addresses]
  }
  # Allow Inbound SSH Traffic
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.all_ipv4_addresses]
  }
  # Allow All Outbound Traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [local.all_ipv4_addresses]
  }
}

################################################################################
# EC2 Instance
################################################################################
resource "aws_instance" "web" {
  ami           = "ami-0c2d06d50ce30b442"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.main.id

  vpc_security_group_ids      = [aws_security_group.sg.id]
  associate_public_ip_address = true

  key_name  = "deployer"
  user_data = file("scripts/dockerweb.sh")

  tags = local.tags
}

resource "aws_eip" "main" {
  vpc = true
}

resource "aws_eip_association" "assoc" {
  instance_id   = aws_instance.web.id
  allocation_id = aws_eip.main.id
}
# 1 GB attached EBS volume
resource "aws_ebs_volume" "vol" {
  availability_zone = local.availability_zone
  size              = 1

  tags = local.tags
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/xvdh"
  volume_id   = aws_ebs_volume.vol.id
  instance_id = aws_instance.web.id
}



