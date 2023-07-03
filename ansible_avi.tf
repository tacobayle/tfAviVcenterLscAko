resource "null_resource" "ansible_hosts_avi_header_1" {
  depends_on = [null_resource.argocd]
  provisioner "local-exec" {
    command = "echo '---' | tee hosts_avi; echo 'all:' | tee -a hosts_avi ; echo '  children:' | tee -a hosts_avi; echo '    controller:' | tee -a hosts_avi; echo '      hosts:' | tee -a hosts_avi"
  }
}

resource "null_resource" "ansible_hosts_avi_controllers" {
  depends_on = [null_resource.ansible_hosts_avi_header_1]
  count            = (var.controller.cluster == true ? 3 : 1)
  provisioner "local-exec" {
    command = "echo '        ${vsphere_virtual_machine.controller[count.index].default_ip_address}:' | tee -a hosts_avi "
  }
}

resource "null_resource" "ansible_hosts_avi_header_2" {
  depends_on = [null_resource.ansible_hosts_avi_controllers]
  provisioner "local-exec" {
    command = "echo '    seLsc:' | tee -a hosts_avi; echo '      hosts:' | tee -a hosts_avi"
  }
}

resource "null_resource" "ansible_hosts_avi_seLsc" {
  depends_on = [null_resource.ansible_hosts_avi_header_2]
  count            = var.avi.config.lsc.serviceEngineGroup.count
  provisioner "local-exec" {
    command = "echo '        ${vsphere_virtual_machine.se[count.index].default_ip_address}:' | tee -a hosts_avi "
  }
}

resource "null_resource" "ansible_hosts_avi_header_3" {
  depends_on = [null_resource.ansible_hosts_avi_seLsc]
  provisioner "local-exec" {
    command = "echo '  vars:' | tee -a hosts_avi ; echo '    ansible_user: ubuntu' | tee -a hosts_avi"
  }
}

data "template_file" "avi_vcenter_yaml_values" {
  template = file("templates/avi_vcenter_yaml_values.yml.template")
  vars = {
    controller_ips = jsonencode(vsphere_virtual_machine.controller[*].default_ip_address)
    controller_ntp = jsonencode(var.controller.ntp)
    controller_dns = jsonencode(var.controller.dns)
    floating_ip = var.controller.floating_ip
    avi_password = var.avi_password
    aviCredsJsonFile = var.controller.aviCredsJsonFile
    avi_old_password = var.avi_old_password
    avi_version = split("-", var.controller.version)[0]
    avi_username = var.avi_username
    vsphere_username = var.vsphere_username
    vsphere_password = var.vsphere_password
    vsphere_server = var.vsphere_server
    tenants = jsonencode(var.avi.config.tenants)
    k8s_tenants = jsonencode(var.vmw.kubernetes.clusters)
    roles = jsonencode(var.avi.config.roles)
    users = jsonencode(var.avi.config.users)
    domains = jsonencode(var.avi.config.vcenter.domains)
    cloud_name = var.avi.config.vcenter.name
    content_library_id = var.avi.config.vcenter.content_library.create == true ? vsphere_content_library.library[0].id : data.vsphere_content_library.library[0].id
    content_library_name = var.avi.config.vcenter.content_library.name
    dc = var.vcenter.dc
    dhcp_enabled = var.avi.config.vcenter.dhcp_enabled
    network_management = jsonencode(var.avi.config.vcenter.networks.network_management)
    network_vip = jsonencode(var.avi.config.vcenter.networks.network_vip)
    network_backend = jsonencode(var.avi.config.vcenter.networks.network_backend)
    service_engine_groups = jsonencode(var.avi.config.vcenter.serviceEngineGroup)
    k8s_service_engine_groups = jsonencode(var.vmw.kubernetes.clusters[*].serviceEngineGroup)
    pools = jsonencode(var.avi.config.vcenter.pools)
    poolgroups = jsonencode(var.avi.config.vcenter.poolgroups)
    httppolicyset = jsonencode(var.avi.config.vcenter.httppolicyset)
    applicationprofile = jsonencode(var.avi.config.vcenter.applicationprofile)
    virtual_services = jsonencode(var.avi.config.vcenter.virtual_services)
  }
}

data "template_file" "avi_lsc_yaml_values" {
  template = file("templates/avi_lsc_yaml_values.yml.template")
  vars = {
    seLsc = jsonencode(vsphere_virtual_machine.se.*.default_ip_address)
    controller = jsonencode(var.controller)
    controller_ips = jsonencode(vsphere_virtual_machine.controller[*].default_ip_address)
    avi_password = var.avi_password
    avi_version = split("-", var.controller.version)[0]
    avi_username = var.avi_username
    avi_servers_lsc = jsonencode(var.backend_lsc.ipsData)
    cloud_name = var.avi.config.lsc.name
    domains = jsonencode(var.avi.config.lsc.domains)
    network_vip = jsonencode(var.avi.config.lsc.networks.network_vip)
    serviceEngineGroup = jsonencode(var.avi.config.lsc.serviceEngineGroup)
    pool =jsonencode(var.avi.config.lsc.pool)
    virtual_services = jsonencode(var.avi.config.lsc.virtualservices)
  }
}

resource "null_resource" "ansible_avi" {
  depends_on = [null_resource.wait_https_controllers, vsphere_virtual_machine.jump, vsphere_virtual_machine.master, vsphere_virtual_machine.worker, null_resource.ansible_hosts_avi_header_3, data.template_file.avi_vcenter_yaml_values, data.template_file.avi_lsc_yaml_values]
  connection {
    host = vsphere_virtual_machine.jump.default_ip_address
    type = "ssh"
    agent = false
    user = var.jump.username
    private_key = file(var.jump.private_key_path)
  }

  provisioner "file" {
    source = "hosts_avi"
    destination = "hosts_avi"
  }

  provisioner "file" {
    content = data.template_file.avi_vcenter_yaml_values.rendered
    destination = "avi_vcenter_yaml_values.yml"
  }

  provisioner "file" {
    content = data.template_file.avi_lsc_yaml_values.rendered
    destination = "avi_lsc_yaml_values.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "git clone ${var.ansible.aviConfigureUrl} --branch ${var.ansible.aviConfigureTag} ; cd ${split("/", var.ansible.aviConfigureUrl)[4]} ; ansible-playbook -i ../hosts_avi vcenter.yml --extra-vars @../avi_vcenter_yaml_values.yml",
      "ansible-playbook -i ../hosts_avi lsc.yml --extra-vars @../avi_lsc_yaml_values.yml",
    ]
  }
}