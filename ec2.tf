resource "aws_instance" "rem_producing_node" {
  ami           = "${var.ubuntu_18_ami}"
  instance_type = "r5.large"
  key_name      = "${aws_key_pair.serg.key_name}"

  vpc_security_group_ids      = ["${aws_security_group.allow_ssh.id}", "${aws_security_group.allow_web.id}", "${aws_security_group.rem_core.id}"]
  subnet_id                   = "${aws_subnet.public_subnet.id}"
  associate_public_ip_address = true
  source_dest_check           = false

  user_data = "${data.template_file.rem_producing_node_init.rendered}"

  tags = {
    Name = "REM Producing Node"
  }

  volume_tags = {
    Name = "REM Producing Node OS"
  }
}

resource "aws_eip" "rem_producing_node_ip" {
  instance   = "${aws_instance.rem_producing_node.id}"
  depends_on = ["aws_internet_gateway.gw"]
  vpc        = true
}

data "template_file" "rem_producing_node_init" {
  template = "${file("user_data/rem_producing_node.sh.tpl")}"

  vars {
    domain           = "${var.eon_domain}"
    account_name     = "${var.testnet_account_name}"
    public_key       = "${var.testnet_public_key}"
    private_key      = "${var.testnet_private_key}"
    rem_peer_address = "${var.rem_peer_address}"
  }
}

resource "aws_instance" "rem_full_node" {
  ami           = "${var.ubuntu_18_ami}"
  instance_type = "t2.large"
  key_name      = "${aws_key_pair.serg.key_name}"

  vpc_security_group_ids      = ["${aws_security_group.allow_ssh.id}", "${aws_security_group.allow_web.id}", "${aws_security_group.rem_core.id}"]
  subnet_id                   = "${aws_subnet.public_subnet.id}"
  associate_public_ip_address = true
  source_dest_check           = false

  user_data = "${data.template_file.rem_full_node_init.rendered}"

  root_block_device {
    volume_size = 20
  }

  tags = {
    Name = "REM Full Node"
  }

  volume_tags = {
    Name = "REM Full Node OS"
  }
}

resource "aws_eip" "rem_full_node" {
  instance   = "${aws_instance.rem_full_node.id}"
  depends_on = ["aws_internet_gateway.gw"]
  vpc        = true
}

data "template_file" "rem_full_node_init" {
  template = "${file("user_data/rem_full_node.sh.tpl")}"

  vars {
    rem_peer_address = "${var.rem_peer_address}"
  }
}
