terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_pool" "virt" {
    name = "virt"
    type = "dir"
    path = "/ssd/virt/pool"
}

data "template_file" "user_data" {
    template = file("${path.module}/user_data")
}

resource "libvirt_cloudinit_disk" "cloud_init_debian" {
    count = length(var.debian_nodes)
    name = "init_debian_${count.index}.iso"
    pool = libvirt_pool.virt.name
    user_data = data.template_file.user_data.rendered
    meta_data = templatefile("${path.module}/meta_data", { hostname = var.debian_nodes[count.index]})
}

resource "libvirt_cloudinit_disk" "cloud_init_rhel" {
	for_each = to_set(var.rhel_nodes)
    name = "init_rhel_${count.index}.iso"
    pool = libvirt_pool.virt.name
    user_data = data.template_file.user_data.rendered
    meta_data = templatefile("${path.module}/meta_data", { hostname = var.rhel_nodes[count.index]})
}

resource "libvirt_volume" "debian_base" {
    name = "debian"
    pool = libvirt_pool.virt.name
    source = "https://cloud.debian.org/images/cloud/bullseye/daily/latest/debian-11-generic-amd64-daily.qcow2"
    format = "qcow2"
}

resource "libvirt_volume" "rhel_base" {
    name = "rhel"
    pool = libvirt_pool.virt.name
    source = "/ssd/virt/images/rhel_base.qcow2"
    format = "qcow2"
}

resource "libvirt_volume" "debian" {
    count = length(var.debian_nodes)
    name = "debian_${count.index}.qcow2"
    pool = libvirt_pool.virt.name
    base_volume_id = libvirt_volume.debian_base.id
}

resource "libvirt_volume" "rhel" {
    count = length(var.rhel_nodes)
    name = "rhel_${count.index}.qcow2"
    pool = libvirt_pool.virt.name
    base_volume_id = libvirt_volume.rhel_base.id
}

resource "libvirt_domain" "debian_nodes" {
    count = length(var.debian_nodes)
    name = var.debian_nodes[count.index]
    memory = 1024
    vcpu = 1
    autostart = true
    qemu_agent = true
    cloudinit = element(libvirt_cloudinit_disk.cloud_init_debian.*.id, count.index)

    network_interface {
        bridge = "br0"
    }

    boot_device {
        dev = ["hd", "network"]
    }

    disk {
        volume_id = element(libvirt_volume.debian.*.id, count.index)
    }

    console {
        type        = "pty"
        target_port = "0"
        target_type = "serial"
    }
    console {
        type        = "pty"
        target_type = "virtio"
        target_port = "1"
      }

    graphics {
        type        = "spice"
        listen_type = "address"
        listen_address = "10.6.0.1"
        autoport    = true
    }  
}

resource "libvirt_domain" "rhel_nodes" {
    count = length(var.rhel_nodes)
    name = var.rhel_nodes[count.index]
    memory = 1024
    vcpu = 1
    autostart = true
    qemu_agent = true
    cloudinit = element(libvirt_cloudinit_disk.cloud_init_rhel.*.id, count.index)

    network_interface {
        bridge = "br0"
    }

    boot_device {
        dev = ["hd", "network"]
    }

    disk {
        volume_id = element(libvirt_volume.rhel.*.id, count.index)
    }

    console {
        type        = "pty"
        target_port = "0"
        target_type = "serial"
    }
    console {
        type        = "pty"
        target_type = "virtio"
        target_port = "1"
      }

    graphics {
        type        = "spice"
        listen_type = "address"
        listen_address = "10.6.0.1"
        autoport    = true
    }  
}
