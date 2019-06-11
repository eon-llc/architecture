resource "aws_instance" "eon" {
  ami                    = "ami-0c6b1d09930fac512"
  instance_type          = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.allow_http.id}", "${aws_security_group.allow_https.id}", "${aws_security_group.allow_ssh.id}"]

  tags = {
    Name = "Website"
  }
}
