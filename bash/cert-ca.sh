#!/bin/bash
directory="openssl"
ca_private_key_passphrase=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 12)
ca_name="root-ca"
key_size=4096
ca_cert_days=1826
CN="My-Root-CA"
C="FR"
ST="Paris"
L="Paris"
O="MyOrganisation"
rm -fr ${directory}
mkdir ${directory}
echo ${ca_private_key_passphrase} | tee ${directory}/ca_private_key_passphrase.txt
openssl genrsa -aes256 -passout pass:${ca_private_key_passphrase} -out ${directory}/${ca_name}.key ${key_size}
openssl req -x509 -new -nodes -passin pass:${ca_private_key_passphrase} -key ${directory}/${ca_name}.key -sha256 -days ${ca_cert_days} -out ${directory}/${ca_name}.crt -subj '/CN='${CN}'/C='${C}'/ST='${ST}'/L='${L}'/O='${O}''