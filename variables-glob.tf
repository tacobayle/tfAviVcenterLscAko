#
# Environment Variables
#
variable "vsphere_username" {}
variable "vsphere_password" {}
variable "vsphere_server" {}
variable "avi_password" {}
variable "avi_old_password" {}
variable "avi_username" {}
variable "docker_registry_username" {}
variable "docker_registry_password" {}
variable "docker_registry_email" {}

variable "avi" {}

variable "jump" {
  type = map
  default = {
    name = "jump"
    cpu = 2
    memory = 4096
    disk = 20
    public_key_path = "~/.ssh/cloudKey.pub"
    private_key_path = "~/.ssh/cloudKey"
    wait_for_guest_net_timeout = 2
    template_name = "ubuntu-focal-20.04-cloudimg-template"
    avisdkVersion = "22.1.5"
    username = "ubuntu"
  }
}

variable "ansible" {
  default = {
    aviPbAbsentUrl = "https://github.com/tacobayle/ansibleAviClear"
    aviPbAbsentTag = "v1.04"
    aviConfigureUrl = "https://github.com/tacobayle/ansibleAviConfig"
    aviConfigureTag = "v1.76"
    version = {
      ansible = "5.7.1"
      ansible-core = "2.12.5"
    }
    k8sInstallUrl = "https://github.com/tacobayle/ansibleK8sInstall"
    k8sInstallTag = "v1.78"
  }
}

variable "controller" {
  default = {
    cpu = 16
    memory = 32768
    disk = 256
    cluster = true
    version = "22.1.5-9093"
    wait_for_guest_net_timeout = 4
    private_key_path = "~/.ssh/cloudKey"
    from_email = "avicontroller@avidemo.fr"
    se_in_provider_context = "true" # true is required for LSC Cloud
    tenant_access_to_provider_se = "true"
    tenant_vrf = "false"
    aviCredsJsonFile = "~/.avicreds.json"
    public_key_path = "~/.ssh/cloudKey.pub"
  }
}

variable "backend_vmw" {
  default = {
    cpu = 2
    memory = 4096
    disk = 20
    username = "ubuntu"
    network = "vxw-dvs-34-virtualwire-117-sid-1080116-sof2-01-vc08-avi-dev113"
    wait_for_guest_net_timeout = 2
    template_name = "ubuntu-bionic-18.04-cloudimg-template"
    netplanFile = "/etc/netplan/50-cloud-init.yaml"
    maskData = "/24"
    url_demovip_server = "https://github.com/tacobayle/demovip_server"
  }
}

variable "backend_vmw_pg" {
  default = {
    cpu = 2
    memory = 4096
    disk = 20
    username = "ubuntu"
    wait_for_guest_net_timeout = 2
    template_name = "ubuntu-bionic-18.04-cloudimg-template"
    netplanFile = "/etc/netplan/50-cloud-init.yaml"
    maskData = "/24"
    url_demovip_server = "https://github.com/tacobayle/demovip_server"
  }
}

variable "backend_lsc" {
  default = {
    cpu = 2
    memory = 4096
    disk = 20
    username = "ubuntu"
    wait_for_guest_net_timeout = 2
    template_name = "ubuntu-bionic-18.04-cloudimg-template"
    netplanFile = "/etc/netplan/50-cloud-init.yaml"
    maskData = "/24"
  }
}

variable "client" {
  default = {
    cpu = 2
    count = 3
    memory = 4096
    disk = 20
    username = "ubuntu"
    wait_for_guest_net_timeout = 2
    template_name = "ubuntu-bionic-18.04-cloudimg-template"
    netplanFile = "/etc/netplan/50-cloud-init.yaml"
    maskData = "/24"
  }
}