resource "vsphere_tag" "ansible_group_client" {
  name             = "client"
  category_id      = vsphere_tag_category.ansible_group_client.id
}

data "template_file" "client_userdata" {
  count = var.client.count
  template = file("${path.module}/userdata/client.userdata")
  vars = {
    username     = var.client.username
    pubkey       = file(var.jump["public_key_path"])
    netplanFile  = var.client.netplanFile
    maskData = var.client.maskData
    ipData      = element(var.vcenter.client_ips, count.index)
    avi_dns_vs = cidrhost(var.avi.config.vcenter.networks.network_vip.cidr, var.avi.config.vcenter.networks.network_vip.ipStartPool)
  }
}

data "vsphere_virtual_machine" "client" {
  name          = var.client["template_name"]
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_virtual_machine" "client" {
  count = var.client.count
  name             = "client-${count.index}"
  datastore_id     = data.vsphere_datastore.datastore.id
  resource_pool_id = data.vsphere_resource_pool.pool.id
  folder           = vsphere_folder.folder.path

  network_interface {
                      network_id = data.vsphere_network.networkMgt.id
  }

  network_interface {
                      network_id = data.vsphere_network.networkClient.id
  }



  num_cpus = var.client["cpu"]
  memory = var.client["memory"]
  wait_for_guest_net_timeout = var.client["wait_for_guest_net_timeout"]
  guest_id = data.vsphere_virtual_machine.client.guest_id
  scsi_type = data.vsphere_virtual_machine.client.scsi_type
  scsi_bus_sharing = data.vsphere_virtual_machine.client.scsi_bus_sharing
  scsi_controller_count = data.vsphere_virtual_machine.client.scsi_controller_scan_count

  disk {
    size             = var.client["disk"]
    label            = "client-${count.index}.lab_vmdk"
    eagerly_scrub    = data.vsphere_virtual_machine.client.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.client.disks.0.thin_provisioned
  }

  cdrom {
    client_device = true
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.client.id
  }

  tags = [
        vsphere_tag.ansible_group_client.id,
  ]


  vapp {
    properties = {
     hostname    = "client-${count.index}"
     public-keys = file(var.jump["public_key_path"])
     user-data   = base64encode(data.template_file.client_userdata[count.index].rendered)
   }
 }

  connection {
    host        = self.default_ip_address
    type        = "ssh"
    agent       = false
    user        = var.client.username
    private_key = file(var.jump["private_key_path"])
    }

  provisioner "remote-exec" {
    inline      = [
      "while [ ! -f /tmp/cloudInitDone.log ]; do sleep 1; done"
    ]
  }
}

resource "null_resource" "clear_ssh_key_clients" {
  count = var.client.count
  provisioner "local-exec" {
    command = "ssh-keygen -f \"/home/ubuntu/.ssh/known_hosts\" -R \"${vsphere_virtual_machine.client[count.index].default_ip_address}\" || true"
  }
}


data "template_file" "traffic_gen" {
  template = file("templates/traffic_gen.sh.template")
  vars = {
    controllerPrivateIp = jsonencode(vsphere_virtual_machine.controller[0].default_ip_address)
    avi_password = jsonencode(var.avi_password)
    avi_username = "admin"
  }
}


resource "null_resource" "traffic_gen_copy" {
  count = var.client.count
  depends_on = [vsphere_virtual_machine.client]

  connection {
    host        = vsphere_virtual_machine.client[count.index].default_ip_address
    type        = "ssh"
    agent       = false
    user        = var.client.username
    private_key = file(var.jump["private_key_path"])
  }

  provisioner "file" {
    source      = "loopback_ips.json"
    destination = "loopback_ips.json"
  }

  provisioner "file" {
    source      = "user_agents.json"
    destination = "user_agents.json"
  }

  provisioner "file" {
    content      = data.template_file.traffic_gen.rendered
    destination = "traffic_gen.sh"
  }


  provisioner "remote-exec" {
    inline = [
      "jq -c -r '.[]' loopback_ips.json | while read ip ; do sudo ip a add $ip dev lo: ; done",
      "chmod u+x /home/${var.client.username}/traffic_gen.sh",
      "(crontab -l 2>/dev/null; echo \"* * * * * /home/${var.client.username}/traffic_gen.sh\") | crontab -"
    ]
  }
}