resource "vsphere_tag" "ansible_group_controller" {
  name             = "controller"
  category_id      = vsphere_tag_category.ansible_group_controller.id
}

data "vsphere_virtual_machine" "controller_template" {
  name          = "controller-${var.controller["version"]}-template"
  datacenter_id = data.vsphere_datacenter.dc.id
}
#
resource "vsphere_virtual_machine" "controller" {
  count            = (var.controller.cluster == true ? 3 : 1)
  name             = "controller-${var.controller["version"]}-${count.index}"
  datastore_id     = data.vsphere_datastore.datastore.id
  resource_pool_id = data.vsphere_resource_pool.pool.id
  folder           = vsphere_folder.folder.path
  network_interface {
    network_id = data.vsphere_network.networkMgt.id
  }

  num_cpus = var.controller["cpu"]
  memory = var.controller["memory"]
  wait_for_guest_net_timeout = var.controller["wait_for_guest_net_timeout"]

  guest_id = data.vsphere_virtual_machine.controller_template.guest_id
  scsi_type = data.vsphere_virtual_machine.controller_template.scsi_type
  scsi_bus_sharing = data.vsphere_virtual_machine.controller_template.scsi_bus_sharing
  scsi_controller_count = data.vsphere_virtual_machine.controller_template.scsi_controller_scan_count

  disk {
    size             = var.controller["disk"]
    label            = "controller-${var.controller["version"]}-${count.index}.lab_vmdk"
    eagerly_scrub    = data.vsphere_virtual_machine.controller_template.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.controller_template.disks.0.thin_provisioned
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.controller_template.id
  }

  tags = [
        vsphere_tag.ansible_group_controller.id,
  ]

  vapp {
    properties = {
      sysadmin-public-key = file(var.controller.public_key_path)
    }
  }
}

resource "null_resource" "wait_https_controllers" {
  depends_on = [vsphere_virtual_machine.controller]
  count            = (var.controller.cluster == true ? 3 : 1)
  provisioner "local-exec" {
    command = "until $(curl --output /dev/null --silent --head -k https://${vsphere_virtual_machine.controller[count.index].default_ip_address}); do echo 'Waiting for Avi Controller to be ready'; sleep 10 ; done"
  }
}

resource "null_resource" "clear_ssh_key_controllers" {
  count            = (var.controller.cluster == true ? 3 : 1)
  provisioner "local-exec" {
    command = "ssh-keygen -f \"/home/ubuntu/.ssh/known_hosts\" -R \"${vsphere_virtual_machine.controller[count.index].default_ip_address}\" || true"
  }
}