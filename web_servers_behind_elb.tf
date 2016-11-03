provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.aws_region}"
}

resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.default.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"
}

resource "aws_subnet" "default" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1c"
}

resource "aws_security_group" "elb" {
  name        = "load_balancer_security_group"
  description = "Load Balancer security group"
  vpc_id      = "${aws_vpc.default.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "default" {
  name        = "http_ssh"
  description = "Basic HTTP and SSH"
  vpc_id      = "${aws_vpc.default.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "consul_ports" {
  name        = "consul_ports"
  description = "Consul member ports"
  vpc_id      = "${aws_vpc.default.id}"

  ingress {
    from_port = 8300
    to_port = 8302
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 8300
    to_port = 8302
    protocol = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 8400
    to_port = 8400
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 8400
    to_port = 8400
    protocol = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 8500
    to_port = 8500
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 8600
    to_port = 8600
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elb" "web" {
  name = "load-balancer"

  subnets         = ["${aws_subnet.default.id}"]
  security_groups = ["${aws_security_group.elb.id}"]
  instances       = ["${aws_instance.web.*.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
}

resource "aws_key_pair" "auth" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}

resource "aws_instance" "web" {
  connection {
    user = "ubuntu"
    private_key = "${file("~/.ssh/id_aws")}"
  }
  count = "3"
  instance_type = "t1.micro"
  availability_zone = "us-east-1c"
  ami = "${lookup(var.images, var.aws_region)}"
  key_name = "${aws_key_pair.auth.id}"
  vpc_security_group_ids = ["${aws_security_group.default.id}",
                            "${aws_security_group.consul_ports.id}"]
  subnet_id = "${aws_subnet.default.id}"
  provisioner "remote-exec" {
    inline = [
      "sudo service nginx start",
      "sudo start consul-server",
      "sudo start consul-template",
      "echo ${aws_instance.web.0.public_ip} > consul_master.txt",
      "consul join `cat consul_master.txt`"
    ]
  }
}