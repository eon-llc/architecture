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

resource "aws_ebs_volume" "rem_rocksdb" {
  availability_zone = "${var.region}a"
  size              = 100
  type              = "gp2"

  tags {
    Name = "REM RocksDB"
  }
}

resource "aws_volume_attachment" "rem_rocksdb_ebs_att" {
  device_name = "/dev/sdf"
  volume_id   = "${aws_ebs_volume.rem_rocksdb.id}"
  instance_id = "${aws_instance.rem_full_node.id}"
}

resource "aws_ebs_volume" "rem_benchmark" {
  availability_zone = "${var.region}a"
  size              = 10
  type              = "gp2"

  tags {
    Name = "REM Benchmark"
  }
}

resource "aws_volume_attachment" "rem_benchmark_ebs_att" {
  device_name = "/dev/sdf"
  volume_id   = "${aws_ebs_volume.rem_benchmark.id}"
  instance_id = "${aws_instance.rem_benchmark.id}"
}
