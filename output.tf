# Outputs for Terraform

output "master" {
  value = vsphere_virtual_machine.master.*.default_ip_address
}

output "workers" {
  value = vsphere_virtual_machine.worker.*.default_ip_address
}

output "jump" {
  value = vsphere_virtual_machine.jump.default_ip_address
}

output "controllers" {
  value = vsphere_virtual_machine.controller.*.default_ip_address
}

output "backend_lsc" {
  value = vsphere_virtual_machine.backend_lsc.*.default_ip_address
}

output "backend_vmw" {
  value = vsphere_virtual_machine.backend_vmw.*.default_ip_address
}

output "backend_vmw_pg" {
  value = vsphere_virtual_machine.backend_vmw_pg.*.default_ip_address
}

output "client" {
  value = vsphere_virtual_machine.client.*.default_ip_address
}

output "load_command" {
  value = "while true ; do ab -n 50 -c 50 https://100.64.133.53/ ; done\n"
}

output "dos_command" {
  value = "requests=\"40\" ; concurrent=\"40\"; while true ; do echo \"sent    : $requests requests\" ; responses=$(ab -v 3 -n $requests -c $concurrent http://app-security.${var.avi.config.vcenter.domains[0].name}/ 2> /dev/null | grep \"LOG: Response code = 200\" | wc -l); echo \"received: $responses successful responses\" ; echo \"---\" ; sleep 1 ; done\n"
}

output "ddos_command_with_cookie" {
  value = "requests=\"100\" ; while true ; do rm results.txt ; echo \"sending $requests requests\" ; for i in $(seq 1 $requests) ; do  curl --cookie \"shop_session-id=15cdd4fe-c97e-42b8-b037-de0b197e490a\" -k https://boutique2.vcenter.avi.com -w \"%%{http_code}\\n\" -o /dev/null -s | tee -a results.txt >/dev/null ; done ; echo \"received $(cat results.txt | grep 200 | wc -l) successful responses\"; echo \"---\"; done\n"
}

#output "ddos_command_without_cookie" {
#  value = "requests=\"40\" ; concurrent=\"40\"; while true ; do echo \"sent    : $requests requests\" ; responses=$(ab -v 3 -n $requests -c $concurrent http://boutique.${var.avi.config.vcenter.domains[0].name}/ 2> /dev/null | grep \"LOG: Response code = 200\" | wc -l); echo \"received: $responses successful responses\" ; echo \"---\" ; sleep 1 ; done\n"
#}

output "destroy" {
  value = "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${basename(var.jump.private_key_path)} -t ubuntu@${vsphere_virtual_machine.jump.default_ip_address} 'git clone ${var.ansible.aviPbAbsentUrl} --branch ${var.ansible.aviPbAbsentTag} ; cd ${split("/", var.ansible.aviPbAbsentUrl)[4]} ; ansible-playbook local.yml --extra-vars @${var.controller.aviCredsJsonFile}' ; sleep 5 ; terraform destroy -auto-approve -var-file=avi.json\n"
  description = "command to destroy the infra"
}

output "destroy_avi" {
  value = "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${basename(var.jump.private_key_path)} -t ubuntu@${vsphere_virtual_machine.jump.default_ip_address} 'git clone ${var.ansible.aviPbAbsentUrl} --branch ${var.ansible.aviPbAbsentTag} ; cd ${split("/", var.ansible.aviPbAbsentUrl)[4]} ; ansible-playbook local.yml --extra-vars @${var.controller.aviCredsJsonFile}'\n"
  description = "command to clear Avi only"
}


output "ako_install" {
  # helm --debug install ako/ako --generate-name --version ${var.vmw.kubernetes.clusters[0].ako.version} -f values.yml --namespace=${var.vmw.kubernetes.clusters[0].ako.namespace} --set avicredentials.username=admin --set avicredentials.password=$avi_password\n
  value = "helm install --generate-name oci://projects.registry.vmware.com/ako/helm-charts/ako --version ${var.vmw.kubernetes.clusters[0].ako.version} -f values.yml --namespace=${var.vmw.kubernetes.clusters[0].ako.namespace} --set avicredentials.username=admin --set avicredentials.password=$avi_password\n"
}

output "amko_install" {
  value = "helm install --generate-name oci://projects.registry.vmware.com/ako/helm-charts/amko  --version ${var.vmw.kubernetes.amko.version} -f /home/ubuntu/amko/values_amko.yml  --namespace=avi-system\n"
}

output "curl_header_command" {
  value = "curl -v -k --header 'X-MyHeader-ToBeReplaced: avi123' --header 'X-MyHeader-ToBeDeleted: avi123' https://app-security.${var.avi.config.vcenter.domains[0].name}\n"
}

output "install_boutique_app" {
  value = "git clone https://github.com/GoogleCloudPlatform/microservices-demo.git \ncd microservices-demo\nkubectl apply -f ./release/kubernetes-manifests.yaml"
  description = "commands to install boutique GCP app"
}