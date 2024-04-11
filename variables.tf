#
# Other Variables
#


variable "vcenter" {
  type = map
  default = {
    dc = "sof2-01-vc08"
    cluster = "sof2-01-vc08c01"
    datastore = "sof2-01-vc08c01-vsan"
    resource_pool = "sof2-01-vc08c01/Resources"
    folder = "nic-vmw-demo"
    networkMgmt = "vxw-dvs-34-virtualwire-3-sid-1080002-sof2-01-vc08-avi-mgmt"
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
            network = "vxw-dvs-34-virtualwire-124-sid-1080123-sof2-01-vc08-avi-dev120"
            wait_for_guest_net_routable = "false"
            template_name = "ubuntu-focal-20.04-cloudimg-template"
            netplanFile = "/etc/netplan/50-cloud-init.yaml"
          }
          worker = {
            cpu = 4
            memory = 8192
            disk = 40
            network = "vxw-dvs-34-virtualwire-124-sid-1080123-sof2-01-vc08-avi-dev120"
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
            network = "vxw-dvs-34-virtualwire-124-sid-1080123-sof2-01-vc08-avi-dev120"
            wait_for_guest_net_routable = "false"
            template_name = "ubuntu-focal-20.04-cloudimg-template"
            netplanFile = "/etc/netplan/50-cloud-init.yaml"
          }
          worker = {
            cpu = 4
            memory = 8192
            disk = 40
            network = "vxw-dvs-34-virtualwire-124-sid-1080123-sof2-01-vc08-avi-dev120"
            wait_for_guest_net_routable = "false"
            template_name = "ubuntu-focal-20.04-cloudimg-template"
            netplanFile = "/etc/netplan/50-cloud-init.yaml"
          }
        },
#        {
#          name = "cluster3"
#          netplanApply = true
#          username = "ubuntu"
#          version = "1.21.3-00"
#          namespaces = [
#            {
#              name= "ns1"
#            },
#            {
#              name= "ns2"
#            },
#            {
#              name= "ns3"
#            },
#          ]
#          ako = {
#            namespace = "avi-system"
#            version = "1.7.2"
#            helm = {
#              url = "https://projects.registry.vmware.com/chartrepo/ako"
#            }
#            values = {
#              AKOSettings = {
#                disableStaticRouteSync = "false"
#              }
#              L7Settings = {
#                serviceType = "ClusterIP"
#                shardVSSize = "SMALL"
#              }
#            }
#          }
#          serviceEngineGroup = {
#            name = "seg-cluster3"
#            ha_mode = "HA_MODE_SHARED"
#            min_scaleout_per_vs = "2"
#            buffer_se = 1
#            vcenter_folder = "nic-vmw-demo"
#          }
#          networks = {
#            pod = "10.244.0.0/16"
#          }
#          docker = {
#            version = "5:20.10.7~3-0~ubuntu-bionic"
#          }
#          interface = "ens224"
#          cni = {
#            url = "https://github.com/coreos/flannel/raw/master/Documentation/kube-flannel.yml"
#            name = "flannel"
#          }
#          master = {
#            count = 1
#            cpu = 8
#            memory = 16384
#            disk = 80
#            network = "vxw-dvs-34-virtualwire-124-sid-1080123-sof2-01-vc08-avi-dev120"
#            wait_for_guest_net_routable = "false"
#            template_name = "ubuntu-bionic-18.04-cloudimg-template"
#            netplanFile = "/etc/netplan/50-cloud-init.yaml"
#          }
#          worker = {
#            cpu = 4
#            memory = 8192
#            disk = 40
#            network = "vxw-dvs-34-virtualwire-124-sid-1080123-sof2-01-vc08-avi-dev120"
#            wait_for_guest_net_routable = "false"
#            template_name = "ubuntu-bionic-18.04-cloudimg-template"
#            netplanFile = "/etc/netplan/50-cloud-init.yaml"
#          }
#        },
      ]
    }
  }
}
