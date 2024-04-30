cd ~/tfAviVcenterLscAko
$(terraform output -json | jq -r .destroy_avi.value)
sleep 5
terraform destroy -auto-approve -var-file=avi.json
cd ~
rm -fr tfAviVcenterLscAko ; git clone https://github.com/tacobayle/tfAviVcenterLscAko ; cd tfAviVcenterLscAko ; terraform init ; terraform apply -auto-approve -var-file=avi.json

# us
cd ~
rm -fr tfAviVcenterLscAko ; git clone https://github.com/tacobayle/tfAviVcenterLscAko ; cd tfAviVcenterLscAko ; cp variables.tf.us variables.tf ; terraform init ; terraform apply -auto-approve -var-file=avi.json
