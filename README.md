# tfAviVcenterLscAko

## Goals
Spin up a full vCenter/LSC/Avi/AKO environment (through Terraform) with:
- vCenter cloud including AKO with n K8S clusters 
- Linux Cloud integration with SE(s) created automatically

## Prerequisites:
- TF installed in the orchestrator VM
- VM templates configured in vCenter:
```
- ubuntu-xenial-16.04-cloudimg-template (which can be downloaded here: http://cloud-images-archive.ubuntu.com/releases/xenial/release-20180105/ubuntu-16.04-server-cloudimg-amd64.ova)
- ubuntu-bionic-18.04-cloudimg-template
- ubuntu-focal-20.04-cloudimg-template
- controller-22.1.5-9093-template
```
- SSH key public and private available defined in jump.public_key_path and jump.private_key_path

## Environment:

Terraform Plan has/have been tested against:

### terraform

```
Terraform v1.0.6
on linux_amd64
+ provider registry.terraform.io/hashicorp/null v3.1.0
+ provider registry.terraform.io/hashicorp/template v2.2.0
+ provider registry.terraform.io/hashicorp/vsphere v2.0.2
```

## variables:
- All the variables are stored in variables.tf
- Credential are configured as environment variables:
```
TF_VAR_vsphere_username=******
TF_VAR_vsphere_server=******
TF_VAR_vsphere_password=******
TF_VAR_avi_password=******
TF_VAR_avi_username=admin
TF_VAR_docker_registry_password=******
TF_VAR_docker_registry_username=******
TF_VAR_docker_registry_email=******
```

## Use the terraform plan to:
- Create a new folder within v-center
- Spin up n Avi Controller:
  - if var.controller.cluster == true then deploy 3 Avi Controller else deploy only 1
  - Avi Version based on var.controller.version
- Spin up n K8S cluster:
  - count based on the length of var.vmw.kubernetes.clusters
  - K8S version based on var.vmw.kubernetes.clusters.*.version
  - Docker version based on var.vmw.kubernetes.clusters.*.docker.version
  - amount of workers based on var.vmw.kubernetes.workers.count  
- Spin up n backend VM(s):
  - count based on the length of var.backend.ipsData
  - with two interfaces: dhcp for mgmt, static for data traffic
  - Hello world app responding on port 80
  - Avi App responding on port 8080
  - Hackazon App responding on port 8081  
- Spin up n client server(s):
  - count based on the length of var.client.count
  - with two interfaces: dhcp for mgmt, dhcp for data traffic  
  - Command to generate a load:
```shell
while true ; do ab -n 1000 -c 1000 https://100.64.133.51/ ; done
``` 
- Spin up a jump server:
  - with ansible and the avisdk installed (via userdata)
  - Create a yaml variable file - in the jump server
  - Call ansible to do the Avi and k8s config. (git clone)

## Run terraform:
```
cd ~ ; rm -fr tfAviVcenterLscAko ; git clone https://github.com/tacobayle/tfAviVcenterLscAko ; cd tfAviVcenterLscAko ; terraform init ; terraform apply -auto-approve -var-file=avi.json
# the terraform will output the command to destroy the environment something like:
```