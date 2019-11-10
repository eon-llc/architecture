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
    Name = "Public subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = "${aws_vpc.eon.id}"
  cidr_block        = "${var.private_subnet_cidr}"
  availability_zone = "${var.region}a"

  tags {
    Name = "Private subnet"
  }
}

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all, for testing"
  vpc_id      = "${aws_vpc.eon.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "Allow all, for testing"
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

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "Allow web traffic"
  }
}

resource "aws_security_group" "rem_core" {
  name        = "rem_core"
  description = "Specific ports for REM Core"
  vpc_id      = "${aws_vpc.eon.id}"

  ingress {
    from_port   = 8888
    to_port     = 8888
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9876
    to_port     = 9876
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9877
    to_port     = 9877
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 2087
    to_port     = 2087
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 8888
    to_port     = 8888
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 9876
    to_port     = 9876
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 9877
    to_port     = 9877
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 2087
    to_port     = 2087
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 123
    to_port     = 123
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "chrony"
  }

  tags {
    Name = "Specific ports for REM Core."
  }
}

resource "aws_security_group" "allow_internal" {
  name        = "allow_internal"
  description = "Allow from public subnet only"
  vpc_id      = "${aws_vpc.eon.id}"

  # ingress {
  #   from_port = 4000
  #   to_port = 4000
  #   protocol = "tcp"
  #   cidr_blocks = ["${var.public_subnet_cidr}"]
  # }

  tags {
    Name = "Allow from public subnet only"
  }
}

resource "aws_security_group" "allow_psql" {
  name        = "allow_psql"
  description = "Allow inbound psql traffic"
  vpc_id      = "${aws_vpc.eon.id}"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "Allow psql traffic"
  }
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow inbound ssh traffic"
  vpc_id      = "${aws_vpc.eon.id}"

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

resource "aws_route_table" "public_route" {
  vpc_id = "${aws_vpc.eon.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags {
    Name = "Public route"
  }
}

resource "aws_route_table_association" "public_route" {
  subnet_id      = "${aws_subnet.public_subnet.id}"
  route_table_id = "${aws_route_table.public_route.id}"
}
