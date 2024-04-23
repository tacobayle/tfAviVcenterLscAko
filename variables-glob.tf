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
    aviConfigureTag = "v2.16"
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
    cpu = 6
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

variable "vmw" {
  default = {
    kubernetes = {
      workers = {
        count = 3
      }
      ako = {
        deploy = false
      }
      amko = {
        app_selector = "gslb"
        version = "1.10.1"
        gslb_domain = "gslb.alb.com"
        deploy = false
      }
      argocd = {
        status = false
        manifest_url = "https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
        namespace = "argocd"
        client_url = "https://github.com/argoproj/argo-cd/releases/download/v2.0.4/argocd-linux-amd64"
      }
      clusters = [
        {
          name = "cluster1" # cluster name
          netplanApply = true
          username = "ubuntu" # default username dor docker and to connect
          version = "v1.28.1-1.1" # k8s version
          namespaces = [
            {
              name= "ns1"
            },
            {
              name= "ns2"
            },
            {
              name= "ns3"
            },
          ]
          ako = {
            namespace = "avi-system"
            version = "1.11.3"
            helm = {
              url = "oci://projects.registry.vmware.com/ako/helm-charts/ako"
            }
            values = {
              AKOSettings = {
                disableStaticRouteSync = "false"
              }
              L7Settings = {
                serviceType = "ClusterIP"
                shardVSSize = "SMALL"
              }
            }
          }
          serviceEngineGroup = {
            name = "seg-cluster1"
            ha_mode = "HA_MODE_SHARED"
            min_scaleout_per_vs = "2"
            buffer_se = 1
            vcenter_folder = "nic-vmw-demo"
          }
          networks = {
            pod = "192.168.0.0/16"
          }
          docker = {
            version = "5:24.0.2-1~ubuntu.20.04~focal"
          }
          cni = {
            url = "https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/tigera-operator.yaml"
            url_crd = "https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/custom-resources.yaml -O"
            name = "calico" # calico or antrea
          }
          master = {
            cpu = 8
            memory = 16384
            disk = 80
            wait_for_guest_net_routable = "false"
            template_name = "ubuntu-focal-20.04-cloudimg-template"
            netplanFile = "/etc/netplan/50-cloud-init.yaml"
          }
          worker = {
            cpu = 4
            memory = 8192
            disk = 40
            wait_for_guest_net_routable = "false"
            template_name = "ubuntu-focal-20.04-cloudimg-template"
            netplanFile = "/etc/netplan/50-cloud-init.yaml"
          }
        },
        {
          name = "cluster2"
          netplanApply = true
          username = "ubuntu"
          version = "v1.28.1-1.1"
          namespaces = [
            {
              name= "ns1"
            },
            {
              name= "ns2"
            },
            {
              name= "ns3"
            },
          ]
          ako = {
            namespace = "avi-system"
            version = "1.11.3"
            helm = {
              url = "https://projects.registry.vmware.com/chartrepo/ako"
            }
            values = {
              AKOSettings = {
                disableStaticRouteSync = "false"
              }
              L7Settings = {
                serviceType = "NodePortLocal"
                shardVSSize = "SMALL"
              }
            }
          }
          serviceEngineGroup = {
            name = "Default-Group"
            ha_mode = "HA_MODE_SHARED"
            min_scaleout_per_vs = 2
            buffer_se = 1
            max_vs_per_se = "20"
            extra_shared_config_memory = 0
            vcenter_folder = "nic-vmw-demo"
            vcpus_per_se = 2
            memory_per_se = 4096
            disk_per_se = 25
            realtime_se_metrics = {
              enabled = true
              duration = 0
            }
          }
          networks = {
            pod = "192.168.1.0/16"
          }
          docker = {
            version = "5:24.0.2-1~ubuntu.20.04~focal"
          }
          cni = {
            url = "https://github.com/vmware-tanzu/antrea/releases/download/v1.2.3/antrea.yml"
            name = "antrea"
            enableNPL = true
          }
          master = {
            count = 1
            cpu = 8
            memory = 16384
            disk = 80
            wait_for_guest_net_routable = "false"
            template_name = "ubuntu-focal-20.04-cloudimg-template"
            netplanFile = "/etc/netplan/50-cloud-init.yaml"
          }
          worker = {
            cpu = 4
            memory = 8192
            disk = 40
            wait_for_guest_net_routable = "false"
            template_name = "ubuntu-focal-20.04-cloudimg-template"
            netplanFile = "/etc/netplan/50-cloud-init.yaml"
          }
        }
      ]
    }
  }
}
