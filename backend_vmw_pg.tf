data "template_file" "backend_vmw_pg_userdata" {
  count = length(var.vcenter.backend_ips_pg)
  template = file("${path.module}/userdata/backend_vmw_pg.userdata")
  vars = {
    username     = var.backend_vmw_pg.username
    pubkey       = file(var.jump["public_key_path"])
    netplanFile  = var.backend_vmw_pg["netplanFile"]
    maskData = var.backend_vmw_pg.maskData
    ipData      = element(var.vcenter.backend_ips_pg, count.index)
    url_demovip_server = var.backend_vmw_pg.url_demovip_server
    docker_registry_username = var.docker_registry_username
    docker_registry_password = var.docker_registry_password
  }
}

data "vsphere_virtual_machine" "backend_vmw_pg" {
  name          = var.backend_vmw_pg["template_name"]
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_virtual_machine" "backend_vmw_pg" {
  count = length(var.vcenter.backend_ips_pg)
  name             = "backend_vmw_pg-${count.index}"
  datastore_id     = data.vsphere_datastore.datastore.id
  resource_pool_id = data.vsphere_resource_pool.pool.id
  folder           = vsphere_folder.folder.path

  network_interface {
                      network_id = data.vsphere_network.networkMgt.id
  }

  network_interface {
                      network_id = data.vsphere_network.networkBackendVmw.id
  }

  num_cpus = var.backend_vmw_pg["cpu"]
  memory = var.backend_vmw_pg["memory"]
  wait_for_guest_net_timeout = var.backend_vmw_pg["wait_for_guest_net_timeout"]
  #wait_for_guest_net_routable = var.backend_vmw_pg["wait_for_guest_net_routable"]
  guest_id = data.vsphere_virtual_machine.backend_vmw_pg.guest_id
  scsi_type = data.vsphere_virtual_machine.backend_vmw_pg.scsi_type
  scsi_bus_sharing = data.vsphere_virtual_machine.backend_vmw_pg.scsi_bus_sharing
  scsi_controller_count = data.vsphere_virtual_machine.backend_vmw_pg.scsi_controller_scan_count

  disk {
    size             = var.backend_vmw_pg["disk"]
    label            = "backend_vmw_pg-${count.index}.lab_vmdk"
    eagerly_scrub    = data.vsphere_virtual_machine.backend_vmw_pg.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.backend_vmw_pg.disks.0.thin_provisioned
  }

  cdrom {
    client_device = true
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.backend_vmw_pg.id
  }

  tags = [
        vsphere_tag.ansible_group_backend.id,
  ]

  vapp {
    properties = {
     hostname    = "backend_vmw_pg-${count.index}"
     public-keys = file(var.jump["public_key_path"])
     user-data   = base64encode(data.template_file.backend_vmw_pg_userdata[count.index].rendered)
   }
 }

  connection {
    host        = self.default_ip_address
    type        = "ssh"
    agent       = false
    user        = var.backend_vmw_pg.username
    private_key = file(var.jump["private_key_path"])
    }

  provisioner "remote-exec" {
    inline      = [
      "while [ ! -f /tmp/cloudInitDone.log ]; do sleep 1; done"
    ]
  }
}

resource "null_resource" "clear_ssh_key_backend_vmw_pg" {
  count = length(var.vcenter.backend_ips_pg)
  provisioner "local-exec" {
    command = "ssh-keygen -f \"/home/ubuntu/.ssh/known_hosts\" -R \"${vsphere_virtual_machine.backend_vmw_pg[count.index].default_ip_address}\" || true"
  }
}