#!/bin/bash

# install filestore.
helm upgrade --install --atomic --timeout 300s --wait-for-jobs filestore -n filestore helm-charts/filestore/ -f examples/filestore/values.yaml --create-namespace

#verify
curl http://filestore.my-hlf-domain.com:31862

#================================================================

# create orderer NS
kubectl create ns orderer

# create secret for Root CA
kubectl -n orderer create secret generic rca-secret --from-literal=user=rca-admin --from-literal=password=rcaComplexPassword

# install root ca
helm upgrade --install --atomic --timeout 300s --wait-for-jobs root-ca -n orderer helm-charts/fabric-ca -f examples/fabric-ca/root-ca.yaml

# verify
curl https://root-ca.my-hlf-domain.com:30448/cainfo --insecure

#================================================================

# create secret for TLS ca
kubectl -n orderer create secret generic tlsca-secret --from-literal=user=tls-admin --from-literal=password=TlsComplexPassword

# install tls ca
helm upgrade --install --atomic --timeout 300s --wait-for-jobs tls-ca -n orderer helm-charts/fabric-ca -f examples/fabric-ca/tls-ca.yaml

# root ca identities
helm upgrade --install --atomic --timeout 300s --wait-for-jobs rootca-ops -n orderer helm-charts/fabric-ops/ -f examples/fabric-ops/rootca/rootca-identities.yaml

# tls ca identities
helm upgrade --install --atomic --timeout 300s --wait-for-jobs tlsca-ops -n orderer helm-charts/fabric-ops/ -f examples/fabric-ops/tlsca/tlsca-identities.yaml

#================================================================================================
# create secret for ica-orderer
kubectl -n orderer create secret generic orderer-secret --from-literal=user=ica-orderer --from-literal=password=icaordererSamplePassword

# orderer ica
helm upgrade --install --atomic --timeout 300s --wait-for-jobs ica-orderer -n orderer helm-charts/fabric-ca -f examples/fabric-ca/ica-orderer.yaml

# create org1 ns
kubectl create ns org1

# create secret for ica-org1
kubectl -n org1 create secret generic org1-secret --from-literal=user=ica-org1 --from-literal=password=icaorg1SamplePassword

# ica-org1
helm upgrade --install --atomic --timeout 300s --wait-for-jobs ica-org1 -n org1 helm-charts/fabric-ca -f examples/fabric-ca/ica-org1.yaml

# register orderer identities
helm upgrade --install --atomic --timeout 300s --wait-for-jobs orderer-ops -n orderer helm-charts/fabric-ops/ -f examples/fabric-ops/orderer/orderer-identities.yaml

# register org1 identities
helm upgrade --install --atomic --timeout 300s --wait-for-jobs org1-ops -n org1 helm-charts/fabric-ops/ -f examples/fabric-ops/org1/identities.yaml

#================================================================

# Generate Genesisblock & Channel transaction file
helm upgrade --install --atomic --timeout 300s --wait-for-jobs cryptogen -n orderer helm-charts/fabric-ops/ -f examples/fabric-ops/orderer/orderer-cryptogen.yaml

# deploy orderers
helm upgrade --install --atomic --timeout 300s --wait-for-jobs orderer -n orderer helm-charts/fabric-orderer/ -f examples/fabric-orderer/orderer.yaml

#================================================

# deploy org1 peers
helm upgrade --install --atomic --timeout 300s --wait-for-jobs peer -n org1 helm-charts/fabric-peer/ -f examples/fabric-peer/org1/values.yaml

#================================================

# create channel
helm upgrade --install --atomic --timeout 300s --wait-for-jobs channelcreate -n org1 helm-charts/fabric-ops/ -f examples/fabric-ops/org1/channel-create.yaml

# update anchor peer
helm upgrade --install --atomic --timeout 300s --wait-for-jobs updateanchorpeer -n org1 helm-charts/fabric-ops/ -f examples/fabric-ops/org1/update-anchor-peer.yaml

#================================================================

# copy chaincode
filestore_pod=$(kubectl get pods -n filestore -l app.kubernetes.io/name=filestore -o jsonpath="{.items[*].metadata.name}")
kubectl cp examples/files/basic-chaincode_go_1.0.tar.gz filestore/"$filestore_pod":/usr/share/nginx/html/yourproject/basic-chaincode_go_1.0.tar.gz

# install chaincode
helm upgrade --install --atomic --timeout 300s --wait-for-jobs installchaincode -n org1 helm-charts/fabric-ops/ -f examples/fabric-ops/org1/install-chaincode.yaml