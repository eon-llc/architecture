resource "aws_ebs_volume" "test_bp" {
  availability_zone = "${var.region}a"
  size              = 30
  type              = "gp2"

  tags {
    Name = "REM Testnet BP"
  }
}

resource "aws_volume_attachment" "test_bp_ebs_att" {
  device_name = "/dev/sdf"
  volume_id   = "${aws_ebs_volume.test_bp.id}"
  instance_id = "${aws_instance.test_bp.id}"
}
