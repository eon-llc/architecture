resource "aws_instance" "test_bp" {
  ami           = "${var.ubuntu_18_ami}"
  instance_type = "r5.large"
  key_name      = "${aws_key_pair.serg.key_name}"

  vpc_security_group_ids      = ["${aws_security_group.allow_ssh.id}", "${aws_security_group.allow_web.id}", "${aws_security_group.rem_core.id}"]
  subnet_id                   = "${aws_subnet.public_subnet.id}"
  associate_public_ip_address = true
  source_dest_check           = false

  user_data = "${data.template_file.test_node_init.rendered}"

  tags = {
    Name = "REM Testnet BP"
  }
}

resource "aws_eip" "test_bp_ip" {
  instance   = "${aws_instance.test_bp.id}"
  depends_on = ["aws_internet_gateway.gw"]
  vpc        = true
}

data "template_file" "test_node_init" {
  template = "${file("user_data/testnet_node.sh.tpl")}"

  vars {
    domain       = "${var.eon_domain}"
    account_name = "${var.testnet_account_name}"
    public_key   = "${var.testnet_public_key}"
    private_key  = "${var.testnet_private_key}"
  }
}
