resource "aws_ebs_volume" "rem_producing_node" {
  availability_zone = "${var.region}a"
  size              = 30
  type              = "gp2"

  tags {
    Name = "REM Producing Node"
  }
}

resource "aws_volume_attachment" "rem_producing_node_ebs_att" {
  device_name = "/dev/sdf"
  volume_id   = "${aws_ebs_volume.rem_producing_node.id}"
  instance_id = "${aws_instance.rem_producing_node.id}"
}

resource "aws_ebs_volume" "rem_postgesql" {
  availability_zone = "${var.region}a"
  size              = 100
  type              = "gp2"

  tags {
    Name = "REM PostgreSQL"
  }
}

resource "aws_volume_attachment" "rem_postgesql_ebs_att" {
  device_name = "/dev/sdf"
  volume_id   = "${aws_ebs_volume.rem_postgesql.id}"
  instance_id = "${aws_instance.rem_full_node.id}"
}
