locals {
  folder_id = "b1gnh3c0khmhhi97erbd"
}

resource "yandex_vpc_network" "akha-k8s-prod" {
  name = "akha-k8s-prod"
}

resource "yandex_vpc_subnet" "akha-k8s-prod" {
  name           = "akha-k8s-prod"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.akha-k8s-prod.id
  v4_cidr_blocks = ["192.168.1.0/24"]
  route_table_id = yandex_vpc_route_table.rt.id
}

resource "yandex_vpc_gateway" "egress" {
  name = "egress"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "rt" {
  name       = "rt"
  network_id = yandex_vpc_network.akha-k8s-prod.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.egress.id
  }
}

resource "yandex_compute_instance" "master" {
  name     = "master"
  hostname = "master"
  resources {
    cores         = 2
    memory        = 8
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd85an6q1o26nf37i2nl"
      size     = 20
    }
  }

  network_interface {
    ip_address     = "192.168.1.100"
    ipv6           = false
    nat            = true
    nat_ip_address = "62.84.119.214"
    subnet_id      = yandex_vpc_subnet.akha-k8s-prod.id
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/akha-yc.pub")}"
  }
}

resource "yandex_compute_instance" "worker" {
  count    = 3
  name     = "worker-${count.index + 1}"
  hostname = "worker-${count.index + 1}"

  resources {
    cores         = 2
    memory        = 8
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd85an6q1o26nf37i2nl"
      size     = 20
    }
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.akha-k8s-prod.id
    nat        = false
    ip_address = "192.168.1.20${count.index + 1}"
    ipv6       = false
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/akha-yc.pub")}"
  }
}
