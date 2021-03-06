provider "aws" {
  region = "${var.aws_region}"
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
}

resource "aws_security_group" "default" {
  name = "first_terraform"
  description = "Used in the terraform"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = "${var.i_ip_range}"
  }
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = "${var.ip_range_tcp}"
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = "${var.e_ip_range}"
  }
}

resource "aws_elb" "web" {
  name = "first-terraform-elb"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c","us-east-1d", "us-east-1e"]

  listener {
    instance_port = 8080
    instance_protocol = "tcp"
    lb_port = 8080
    lb_protocol = "tcp"
  }
  listener {
    instance_port = 8080
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }
  instances = ["${aws_instance.web.id}"]
}

resource "aws_instance" "web" {
  connection {
    user = "ubuntu"
  }
  instance_type = "t2.micro"
  ami = "${lookup(var.aws_amis, var.aws_region)}"
  key_name = "${var.key_name}"
  security_groups = ["${aws_security_group.default.name}"]
}

resource "aws_launch_configuration" "example" {
  image_id = "${lookup(var.aws_amis, var.aws_region)}"
  instance_type = "t2.micro"
  security_groups = ["${aws_security_group.default.id}"]
  key_name = "${var.key_name}"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "example" {
  launch_configuration = "${aws_launch_configuration.example.id}"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c","us-east-1d", "us-east-1e"]
  min_size = 1
  max_size = 1
  load_balancers = ["${aws_elb.web.name}"]
  health_check_type = "ELB"
  tag {
    key = "Name"
    value = "microservice-with-terraform"
    propagate_at_launch = true
  }
}


