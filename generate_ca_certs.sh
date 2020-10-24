openssl genrsa -des3 -out CA-key.pem 2048
openssl req -new -key CA-key.pem -x509 -days 1000 -out CA-cert.pem

# we need to add subjectAltName = IP:35.196.194.251 in the [ v3_ca ] section of openssh.cnf
openssl req -new -config openssl.cnf -extensions v3_ca -key CA-key.pem -out signingReq.csr
openssl x509 -req -days 365 -in signingReq.csr -extfile openssl.cnf -extensions v3_ca -CA CA-cert.pem -CAkey CA-key.pem -CAcreateserial -out CA-cert.pem
openssl pkcs8 -topk8 -inform PEM -outform PEM -nocrypt -in CA-key.pem -out CA-key2.pem
sudo cp CA-key2.pem /var/lib/neo4j/certificates/neo4j.key
sudo cp CA-cert.pem /var/lib/neo4j/certificates/neo4j.cert
sudo service neo4j restart
