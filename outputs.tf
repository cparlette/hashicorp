output "elb_address" {
  value = "${aws_elb.web.dns_name}"
}

output "web_servers" {
    value = "${ join(", ", aws_instance.web.*.public_ip) }"
}
