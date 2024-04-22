#!/bin/bash
directory="openssl"
ca_name="root-ca"
ca_private_key_passphrase=$(cat ${directory}/ca_private_key_passphrase.txt)
echo ${ca_private_key_passphrase}
name="app_cert"
cn="My_App"
c="FR"
st="Paris"
l="Paris"
org="MyOrganisation"
days=3
echo ${directory}/${name}.csr
echo ${directory}/${name}.key
echo /CN='${cn}'/C='${c}'/ST='${st}'/L='${l}'/O='${org}'
openssl req -new -nodes -out ${directory}/${name}.csr -newkey rsa:4096 -keyout ${directory}/${name}.key -subj '/CN='${cn}'/C='${c}'/ST='${st}'/L='${l}'/O='${org}''
openssl x509 -req -in ${directory}/${name}.csr -CA ${directory}/${ca_name}.crt -passin pass:${ca_private_key_passphrase} -CAkey ${directory}/${ca_name}.key -CAcreateserial -out ${directory}/${name}.crt -days ${days} -sha256