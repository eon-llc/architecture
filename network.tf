resource "aws_vpc" "eon" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true

  tags {
    Name = "Eon VPC"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.eon.id}"

  tags {
    Name = "Eon VPC Gateway"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id            = "${aws_vpc.eon.id}"
  cidr_block        = "${var.public_subnet_cidr}"
  availability_zone = "${var.region}a"

  tags {
    Name = "Public subnet for web traffic"
  }
}

# Define the private subnet
resource "aws_subnet" "private_subnet" {
  vpc_id            = "${aws_vpc.eon.id}"
  cidr_block        = "${var.private_subnet_cidr}"
  availability_zone = "${var.region}b"

  tags {
    Name = "Private subnet"
  }
}

resource "aws_security_group" "allow_web" {
  name        = "allow_web"
  description = "Allow inbound http traffic."
  vpc_id      = "${aws_vpc.eon.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "Allow web traffic"
  }
}

resource "aws_security_group" "allow_internal" {
  name        = "allow_internal"
  description = "Allow traffic from public subnet only"
  vpc_id      = "${aws_vpc.eon.id}"

  # ingress {
  #   from_port = 4000
  #   to_port = 4000
  #   protocol = "tcp"
  #   cidr_blocks = ["${var.public_subnet_cidr}"]
  # }

  tags {
    Name = "DB SG"
  }
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow inbound ssh traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "Allow ssh traffic"
  }
}

resource "aws_route_table" "web_public_rt" {
  vpc_id = "${aws_vpc.eon.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags {
    Name = "Public subnet route table"
  }
}

resource "aws_route_table_association" "web_public_rt" {
  subnet_id      = "${aws_subnet.public_subnet.id}"
  route_table_id = "${aws_route_table.web_public_rt.id}"
}
