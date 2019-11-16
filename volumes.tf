resource "aws_ebs_volume" "rem_producing_node" {
  availability_zone = "${var.region}a"
  size              = 30
  type              = "gp2"

  tags {
    Name     = "REM Producing Node"
    Snapshot = "true"
  }
}

resource "aws_volume_attachment" "rem_producing_node_ebs_att" {
  device_name = "/dev/sdf"
  volume_id   = "${aws_ebs_volume.rem_producing_node.id}"
  instance_id = "${aws_instance.rem_producing_node.id}"
}

resource "aws_ebs_volume" "rem_full_node_api_db" {
  availability_zone = "${var.region}a"
  size              = 100
  type              = "gp2"

  tags {
    Name     = "REM Full Node"
    Snapshot = "true"
  }
}

resource "aws_volume_attachment" "rem_full_node_api_db_ebs_att" {
  device_name = "/dev/sdf"
  volume_id   = "${aws_ebs_volume.rem_full_node_api_db.id}"
  instance_id = "${aws_instance.rem_full_node.id}"
}

resource "aws_ebs_volume" "rem_benchmark" {
  availability_zone = "${var.region}a"
  size              = 10
  type              = "gp2"

  tags {
    Name     = "REM Benchmark"
    Snapshot = "true"
  }
}

resource "aws_volume_attachment" "rem_benchmark_ebs_att" {
  device_name = "/dev/sdf"
  volume_id   = "${aws_ebs_volume.rem_benchmark.id}"
  instance_id = "${aws_instance.rem_benchmark.id}"
}

resource "aws_dlm_lifecycle_policy" "snapshot_all" {
  description        = "Back up twice a day and retain 2"
  execution_role_arn = "${aws_iam_role.dlm_lifecycle_role.arn}"
  state              = "ENABLED"

  policy_details {
    resource_types = ["VOLUME"]

    schedule {
      name = "Back up twice a day and retain 2"

      create_rule {
        interval      = 12
        interval_unit = "HOURS"
        times         = ["12:00"]
      }

      retain_rule {
        count = 2
      }

      copy_tags = true
    }

    target_tags = {
      Snapshot = "true"
    }
  }
}
