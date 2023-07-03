resource "vsphere_tag" "ansible_group_se" {
  name             = "seLsc"
  category_id      = vsphere_tag_category.ansible_group_se.id
}

data "template_file" "se_userdata" {
  template = file("${path.module}/userdata/se.userdata")
  count = var.avi.config.lsc.serviceEngineGroup.count
  vars = {
    pubkey = file(var.avi.config.lsc.serviceEngineGroup.public_key_path)
    username = var.avi.config.lsc.serviceEngineGroup.username
    kernelVersion = var.avi.config.lsc.serviceEngineGroup.kernel_version
  }
}

data "vsphere_virtual_machine" "se" {
  name          = var.avi.config.lsc.serviceEngineGroup.templateName
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_virtual_machine" "se" {
  count = var.avi.config.lsc.serviceEngineGroup.count
  name             = "seLsc-${count.index}"
  datastore_id     = data.vsphere_datastore.datastore.id
  resource_pool_id = data.vsphere_resource_pool.pool.id
  folder           = vsphere_folder.folder.path

  dynamic network_interface {
    for_each = [for network in data.vsphere_network.networksLsc:{
      id = network.id
    }]
    content {
      network_id = network_interface.value.id
      }
    }

  num_cpus = var.avi.config.lsc.serviceEngineGroup.vcpus_per_se
  memory = var.avi.config.lsc.serviceEngineGroup.memory_per_se
  guest_id = data.vsphere_virtual_machine.se.guest_id
  scsi_type = data.vsphere_virtual_machine.se.scsi_type
  scsi_bus_sharing = data.vsphere_virtual_machine.se.scsi_bus_sharing
  scsi_controller_count = data.vsphere_virtual_machine.se.scsi_controller_scan_count

  disk {
    size             = var.avi.config.lsc.serviceEngineGroup.disk_per_se
    label            = "se-${count.index}.lab_vmdk"
    eagerly_scrub    = data.vsphere_virtual_machine.se.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.se.disks.0.thin_provisioned
  }

  cdrom {
    client_device = true
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.se.id
  }

  tags = [
    vsphere_tag.ansible_group_se.id,
  ]

  vapp {
    properties = {
      hostname    = "se-${count.index}"
      public-keys = file(var.avi.config.lsc.serviceEngineGroup.public_key_path)
      user-data   = base64encode(data.template_file.se_userdata[count.index].rendered)
    }
  }

  connection {
    host        = self.default_ip_address
    type        = "ssh"
    agent       = false
    user        = var.avi.config.lsc.serviceEngineGroup.username
    private_key = file(var.avi.config.lsc.serviceEngineGroup.private_key_path)
  }

  provisioner "remote-exec" {
    inline      = [
      "while [ ! -f /tmp/cloudInitDone.log ]; do sleep 1; done"
    ]
  }
}
