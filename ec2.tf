resource "aws_instance" "rem_producing_node" {
  ami           = "${var.ubuntu_18_net_ami}"
  instance_type = "c5.large"
  key_name      = "${aws_key_pair.serg.key_name}"

  vpc_security_group_ids      = ["${aws_security_group.allow_ssh.id}", "${aws_security_group.allow_web.id}", "${aws_security_group.rem_core.id}"]
  subnet_id                   = "${aws_subnet.public_subnet.id}"
  associate_public_ip_address = true
  source_dest_check           = false

  user_data = "${data.template_file.rem_producing_node_init.rendered}"

  tags = {
    Name = "REM Producing Node"
  }
}

resource "aws_eip" "rem_producing_node" {
  instance   = "${aws_instance.rem_producing_node.id}"
  depends_on = ["aws_internet_gateway.gw"]
  vpc        = true

  tags = {
    Name = "REM Producing Node"
  }
}

data "template_file" "rem_producing_node_init" {
  template = "${file("user_data/rem_producing_node.sh.tpl")}"

  vars {
    domain                = "${var.eon_domain}"
    permission_name       = "${var.rem_permission_name}"
    account_name          = "${var.rem_account_name}"
    public_key            = "${var.rem_public_key}"
    private_key           = "${var.rem_private_key}"
    rem_peer_address      = "${var.rem_peer_address}"
    discord_channel       = "${var.discord_channel}"
    eth_wss_provider      = "${var.rem_eth_wss_provider}"
    cryptocompare_api_key = "${var.rem_cryptocompare_api_key}"
  }
}

resource "aws_instance" "rem_full_node" {
  ami           = "${var.ubuntu_18_net_ami}"
  instance_type = "t2.medium"
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
}

resource "aws_eip" "rem_full_node" {
  instance   = "${aws_instance.rem_full_node.id}"
  depends_on = ["aws_internet_gateway.gw"]
  vpc        = true

  tags = {
    Name = "REM Full Node"
  }
}

data "template_file" "rem_full_node_init" {
  template = "${file("user_data/rem_full_node.sh.tpl")}"

  vars {
    rem_peer_address      = "${var.rem_peer_address}"
    benchmark_db_ip       = "${aws_eip.rem_benchmark.public_ip}"
    benchmark_db          = "${var.benchmark_db}"
    benchmark_table       = "${var.benchmark_table}"
    benchmark_user        = "${var.benchmark_user}"
    benchmark_pass        = "${var.benchmark_pass}"
    benchmark_db_port     = "${var.benchmark_db_port}"
    benchmark_private_key = "${var.benchmark_private_key}"
    benchmark_wallet_name = "${var.benchmark_wallet_name}"
    benchmark_wallet_pass = "${var.benchmark_wallet_pass}"
    discord_channel       = "${var.discord_channel}"
    hyperion_user         = "${var.hyperion_user}"
    hyperion_pass         = "${var.hyperion_pass}"
  }
}

resource "aws_instance" "rem_benchmark" {
  ami           = "${var.ubuntu_18_ami}"
  instance_type = "t2.micro"
  key_name      = "${aws_key_pair.serg.key_name}"

  vpc_security_group_ids      = ["${aws_security_group.allow_ssh.id}", "${aws_security_group.allow_web.id}", "${aws_security_group.allow_psql.id}"]
  subnet_id                   = "${aws_subnet.public_subnet.id}"
  associate_public_ip_address = true
  source_dest_check           = false

  user_data = "${data.template_file.rem_benchmark_node_init.rendered}"

  root_block_device {
    volume_size = 8
  }

  tags = {
    Name = "REM Benchmark"
  }
}

resource "aws_eip" "rem_benchmark" {
  instance   = "${aws_instance.rem_benchmark.id}"
  depends_on = ["aws_internet_gateway.gw"]
  vpc        = true

  tags = {
    Name = "REM Benchmark"
  }
}

data "template_file" "rem_benchmark_node_init" {
  template = "${file("user_data/rem_benchmark_node.sh.tpl")}"

  vars {
    benchmark_db      = "${var.benchmark_db}"
    benchmark_table   = "${var.benchmark_table}"
    benchmark_user    = "${var.benchmark_user}"
    benchmark_pass    = "${var.benchmark_pass}"
    benchmark_db_port = "${var.benchmark_db_port}"
  }
}
