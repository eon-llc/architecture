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

resource "aws_subnet" "public_subnet_a" {
  vpc_id            = "${aws_vpc.eon.id}"
  cidr_block        = "${var.public_subnet_a_cidr}"
  availability_zone = "${var.region}a"

  tags {
    Name = "Public subnet a for web traffic"
  }
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id            = "${aws_vpc.eon.id}"
  cidr_block        = "${var.public_subnet_b_cidr}"
  availability_zone = "${var.region}b"

  tags {
    Name = "Public subnet b for web traffic"
  }
}

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

resource "aws_route_table" "public_route_a" {
  vpc_id = "${aws_vpc.eon.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags {
    Name = "Public route a"
  }
}

resource "aws_route_table" "public_route_b" {
  vpc_id = "${aws_vpc.eon.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags {
    Name = "Public route a"
  }
}

resource "aws_route_table_association" "public_route_a" {
  subnet_id      = "${aws_subnet.public_subnet_a.id}"
  route_table_id = "${aws_route_table.public_route_a.id}"
}

resource "aws_route_table_association" "public_route_b" {
  subnet_id      = "${aws_subnet.public_subnet_b.id}"
  route_table_id = "${aws_route_table.public_route_b.id}"
}
