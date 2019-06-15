resource "aws_instance" "eon-website" {
  ami           = "${var.amazon_linux_ami}"
  instance_type = "t2.micro"

  subnet_id                   = "${aws_subnet.public_subnet.id}"
  vpc_security_group_ids      = ["${aws_security_group.allow_web.id}"]
  associate_public_ip_address = true
  source_dest_check           = false

  tags = {
    Name = "Eon Website"
  }
}
