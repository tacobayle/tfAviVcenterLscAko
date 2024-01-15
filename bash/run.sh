cd ~/tfVmwAviVcenterLscAko
$(terraform output -json | jq -r .destroy_avi.value)
sleep 5
terraform destroy -auto-approve -var-file=avi.json
cd ~
rm -fr tfVmwAviVcenterLscAko ; git clone https://github.com/tacobayle/tfVmwAviVcenterLscAko ; cd tfVmwAviVcenterLscAko ; terraform init ; terraform apply -auto-approve -var-file=avi.json