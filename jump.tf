resource "vsphere_tag" "ansible_group_jump" {
  name             = "jump"
  category_id      = vsphere_tag_category.ansible_group_jump.id
}

data "template_file" "jumpbox_userdata" {
  template = file("${path.module}/userdata/jump.userdata")
  vars = {
    pubkey        = file(var.jump["public_key_path"])
    avisdkVersion = var.jump["avisdkVersion"]
    ansible_version = var.ansible.version.ansible
    ansible_core_version = var.ansible.version.ansible-core
    vsphere_username  = var.vsphere_username
    vsphere_password = var.vsphere_password
    vsphere_server = var.vsphere_server
    username = var.jump["username"]
    privateKey = var.jump["private_key_path"]
  }
}

data "vsphere_virtual_machine" "jump" {
  name          = var.jump["template_name"]
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_virtual_machine" "jump" {
  name             = var.jump["name"]
  datastore_id     = data.vsphere_datastore.datastore.id
  resource_pool_id = data.vsphere_resource_pool.pool.id
  folder           = vsphere_folder.folder.path
  network_interface {
                      network_id = data.vsphere_network.networkMgt.id
  }

  num_cpus = var.jump["cpu"]
  memory = var.jump["memory"]
  wait_for_guest_net_timeout = var.jump["wait_for_guest_net_timeout"]
  guest_id = data.vsphere_virtual_machine.jump.guest_id
  scsi_type = data.vsphere_virtual_machine.jump.scsi_type
  scsi_bus_sharing = data.vsphere_virtual_machine.jump.scsi_bus_sharing
  scsi_controller_count = data.vsphere_virtual_machine.jump.scsi_controller_scan_count

  disk {
    size             = var.jump["disk"]
    label            = "jump.lab_vmdk"
    eagerly_scrub    = data.vsphere_virtual_machine.jump.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.jump.disks.0.thin_provisioned
  }

  cdrom {
    client_device = true
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.jump.id
  }

  tags = [
        vsphere_tag.ansible_group_jump.id,
  ]

  vapp {
    properties = {
     hostname    = "jump"
     public-keys = file(var.jump["public_key_path"])
     user-data   = base64encode(data.template_file.jumpbox_userdata.rendered)
   }
 }

  connection {
   host        = self.default_ip_address
   type        = "ssh"
   agent       = false
   user        = var.jump.username
   private_key = file(var.jump["private_key_path"])
  }

  provisioner "remote-exec" {
   inline      = [
     "while [ ! -f /tmp/cloudInitDone.log ]; do sleep 1; done"
   ]
  }

  provisioner "file" {
    source      = var.jump["private_key_path"]
    destination = "~/.ssh/${basename(var.jump["private_key_path"])}"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 600 ~/.ssh/${basename(var.jump.private_key_path)}"
    ]
  }

    provisioner "remote-exec" {
      inline = [
        "mkdir amko"
      ]
  }

}

resource "null_resource" "clear_ssh_key_jump" {
  provisioner "local-exec" {
    command = "ssh-keygen -f \"/home/ubuntu/.ssh/known_hosts\" -R \"${vsphere_virtual_machine.jump.default_ip_address}\" || true"
  }
}