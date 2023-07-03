resource "null_resource" "copy_k8s_config_file_to_jump" {
  depends_on = [null_resource.ansible_bootstrap_cluster]
  count      = length(var.vmw.kubernetes.clusters)
  connection {
    host        = vsphere_virtual_machine.jump.default_ip_address
    type        = "ssh"
    agent       = false
    user        = var.jump.username
    private_key = file(var.jump.private_key_path)
  }

  provisioner "remote-exec" {
    inline = [
      "scp -i ${var.jump.private_key_path} -o StrictHostKeyChecking=no ubuntu@${vsphere_virtual_machine.master[count.index].default_ip_address}:/home/ubuntu/.kube/config /home/ubuntu/amko/config${count.index + 1}"
    ]
  }
}


data "template_file" "script_amko" {
  template = file("templates/script_amko.sh.template")
  vars = {
    controller_ip = vsphere_virtual_machine.controller[0].default_ip_address
    controller_version = split("-", var.controller.version)[0]
    cluster = length(var.vmw.kubernetes.clusters)
    avi_password = var.avi_password
    avi_version = split("-", var.controller.version)[0]
    app_selector = var.vmw.kubernetes.amko.app_selector
  }
}

data "template_file" "crd_gslb" {
  count      = length(var.vmw.kubernetes.clusters)
  template = file("templates/crd_gslb.yml.template")
  vars = {
    domain = var.avi.config.vcenter.domains.0.name
    gslb_domain = var.vmw.kubernetes.amko.gslb_domain
    cluster = count.index + 1
  }
}

data "template_file" "crd_gslbhostrule" {
  count      = length(var.vmw.kubernetes.clusters)
  template = file("templates/crd_gslbhostrule.yml.template")
  vars = {
    gslb_domain = var.vmw.kubernetes.amko.gslb_domain
  }
}



data "template_file" "ingress_gslb" {
  count      = length(var.vmw.kubernetes.clusters)
  template = file("templates/ingress_gslb.yml.template")
  vars = {
    gslb_label = var.vmw.kubernetes.amko.app_selector
    domain = var.avi.config.vcenter.domains.0.name
    cluster = count.index + 1
  }
}

resource "null_resource" "jump_amko" {
  depends_on = [null_resource.copy_k8s_config_file_to_jump]
  connection {
    host = vsphere_virtual_machine.jump.default_ip_address
    type = "ssh"
    agent = false
    user = var.jump.username
    private_key = file(var.jump.private_key_path)
  }

  provisioner "file" {
    content = data.template_file.script_amko.rendered
    destination = "/home/ubuntu/amko/amko.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod u+x /home/ubuntu/amko/amko.sh",
      "/bin/bash /home/ubuntu/amko/amko.sh",
    ]
  }
}

resource "null_resource" "copy_k8s_config_amko_to_masters" {
  depends_on = [null_resource.jump_amko]
  count      = length(var.vmw.kubernetes.clusters)
  connection {
    host        = vsphere_virtual_machine.jump.default_ip_address
    type        = "ssh"
    agent       = false
    user        = var.jump.username
    private_key = file(var.jump.private_key_path)
  }

  provisioner "remote-exec" {
    inline = [
      "scp -i ${var.jump.private_key_path} -o StrictHostKeyChecking=no /home/ubuntu/amko/gslb-members ubuntu@${vsphere_virtual_machine.master[count.index].default_ip_address}:/home/ubuntu/amko/gslb-members",
      "scp -i ${var.jump.private_key_path} -o StrictHostKeyChecking=no /home/ubuntu/amko/values_amko${count.index + 1}.yml ubuntu@${vsphere_virtual_machine.master[count.index].default_ip_address}:/home/ubuntu/amko/values_amko.yml"
    ]
  }
}

resource "null_resource" "amko_prerequisites" {
  depends_on = [null_resource.copy_k8s_config_amko_to_masters]
  count = length(var.vmw.kubernetes.clusters)
  connection {
    host = vsphere_virtual_machine.master[count.index].default_ip_address
    type = "ssh"
    agent = false
    user = var.vmw.kubernetes.clusters[count.index].username
    private_key = file(var.jump.private_key_path)
  }

  provisioner "file" {
    content = data.template_file.crd_gslb[count.index].rendered
    destination = "/home/ubuntu/crd_gslb.yml"
  }

  provisioner "file" {
    content = data.template_file.crd_gslbhostrule[count.index].rendered
    destination = "/home/ubuntu/crd_gslbhostrule.yml"
  }
  
  provisioner "file" {
    content = data.template_file.ingress_gslb[count.index].rendered
    destination = "/home/ubuntu/ingress_gslb.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "kubectl create secret generic gslb-config-secret --from-file /home/ubuntu/amko/gslb-members -n avi-system"
    ]
  }
}

resource "null_resource" "install_amko" {
  depends_on = [null_resource.amko_prerequisites]
  count = (var.vmw.kubernetes.amko.deploy == true ? length(var.vmw.kubernetes.clusters) : 0)
  connection {
    host = vsphere_virtual_machine.master[count.index].default_ip_address
    type = "ssh"
    agent = false
    user = var.vmw.kubernetes.clusters[count.index].username
    private_key = file(var.jump.private_key_path)
  }

  provisioner "remote-exec" {
    inline = [
      "helm install  ako/amko  --generate-name --version ${var.vmw.kubernetes.amko.version} -f /home/ubuntu/amko/values_amko.yml  --namespace=avi-system"
    ]
  }
}