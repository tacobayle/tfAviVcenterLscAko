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
    ipData      = element(var.client.ipsData, count.index)
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


resource "null_resource" "traffic_gen1" {
  provisioner "local-exec" {
    command = "echo '#!/bin/bash' | tee traffic_gen.sh"
  }
}

resource "null_resource" "traffic_gen_vcenter_1" {
  depends_on = [null_resource.traffic_gen1]
  count = length(var.avi.config.vcenter.virtual_services.http)
  provisioner "local-exec" {
    command = "echo 'for i in {1..20}; do curl -k https://${var.avi.config.vcenter.virtual_services.http[count.index].name}.${var.avi.config.vcenter.domains[0].name}; sleep 0.5 ; done' | tee -a traffic_gen.sh"
  }
}

resource "null_resource" "traffic_gen_vcenter_2" {
  depends_on = [null_resource.traffic_gen_vcenter_1]
  provisioner "local-exec" {
    command = "echo 'for i in {1..30}; do curl -k https://${var.avi.config.vcenter.virtual_services.http[length(var.avi.config.vcenter.virtual_services.http) - 1 ].name}.${var.avi.config.vcenter.domains[0].name}/wrongpath; sleep 0.5 ; done' | tee -a traffic_gen.sh"
  }
}

resource "null_resource" "traffic_gen_lsc" {
  depends_on = [null_resource.traffic_gen_vcenter_2]
  count      = length(var.avi.config.lsc.virtualservices.http)

  provisioner "local-exec" {
    command = "echo 'for i in {1..10}; do curl -k https://${var.avi.config.lsc.virtualservices.http[count.index].name}.${var.avi.config.lsc.domains[0].name}; sleep 0.5 ; done' | tee -a traffic_gen.sh"
  }

}

resource "null_resource" "traffic_gen_copy" {
  count = var.client.count
  depends_on = [null_resource.traffic_gen_lsc]

  connection {
    host        = vsphere_virtual_machine.client[count.index].default_ip_address
    type        = "ssh"
    agent       = false
    user        = var.client.username
    private_key = file(var.jump["private_key_path"])
  }

  provisioner "file" {
    source      = "traffic_gen.sh"
    destination = "traffic_gen.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod u+x /home/${var.client.username}/traffic_gen.sh",
      "(crontab -l 2>/dev/null; echo \"* * * * * /home/${var.client.username}/traffic_gen.sh\") | crontab -"
    ]
  }
}