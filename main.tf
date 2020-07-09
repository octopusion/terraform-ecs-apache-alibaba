# Configure the Alicloud Provider
provider "alicloud" {
  access_key = "${var.access_key}"
  secret_key = "${var.access_key_secret}"
  region     = "${var.region}"
}

# Configure zones
data "alicloud_zones" "ali_zones" {}

# Configure instance
data "alicloud_instance_types" "c2m4" {
  memory_size       = 4
  cpu_core_count    = 2
  availability_zone = "${data.alicloud_zones.ali_zones.zones.0.id}"
}

# Configure vpc
resource "alicloud_vpc" "ecs-vpc" {
  name       = "ecs-vpc"
  cidr_block = "192.168.0.0/16"
}

# Configure vswitch
resource "alicloud_vswitch" "ecs-vswitch" {
  name              = "ecs-vswitch"
  vpc_id            = "${alicloud_vpc.ecs-vpc.id}"
  cidr_block        = "192.168.0.0/24"
  availability_zone = "${data.alicloud_zones.ali_zones.zones.0.id}"
}

# Configure Security Group
resource "alicloud_security_group" "ecs-sg" {
  name        = "ecs-sg"
  vpc_id      = "${alicloud_vpc.ecs-vpc.id}"
  description = "Webserver security group"
}

resource "alicloud_security_group_rule" "http-in" {
  type              = "ingress"
  ip_protocol       = "tcp"
  policy            = "accept"
  port_range        = "80/80"
  security_group_id = "${alicloud_security_group.ecs-sg.id}"
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "ssh-in" {
  type              = "ingress"
  ip_protocol       = "tcp"
  policy            = "accept"
  port_range        = "22/22"
  security_group_id = "${alicloud_security_group.ecs-sg.id}"
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "icmp-in" {
  type              = "ingress"
  ip_protocol       = "icmp"
  policy            = "accept"
  port_range        = "-1/-1"
  security_group_id = "${alicloud_security_group.ecs-sg.id}"
  cidr_ip           = "0.0.0.0/0"
}

# Configure Key Pair
resource "alicloud_key_pair" "ecs-ssh-key" {
  key_name = "ecs-ssh-key"
  key_file = "ecs-ssh-key.pem"
}

# Configure ECS Instance
resource "alicloud_instance" "ecs-instance" {
  instance_name = "ecs-instance"

  image_id = "${var.alicloud_image_id}"

  instance_type        = "${data.alicloud_instance_types.c2m4.instance_types.0.id}"
  system_disk_category = "cloud_efficiency"
  security_groups      = ["${alicloud_security_group.ecs-sg.id}"]
  vswitch_id           = "${alicloud_vswitch.ecs-vswitch.id}"

  user_data = "${file("install_apache.sh")}"

  key_name = "${alicloud_key_pair.ecs-ssh-key.key_name}"

  internet_max_bandwidth_out = 10
}
