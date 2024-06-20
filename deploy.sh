#!/bin/bash

echo -e "\nstart time: $(date '+%F %T')\n"

# install filestore.
helm upgrade --install --atomic --timeout 300s --wait-for-jobs install filestore -n filestore helm-charts/filestore/ -f examples/filestore/values.yaml --create-namespace

# create orderer NS
kubectl create ns orderer

# create secret for Root CA
kubectl -n orderer create secret generic rca-secret --from-literal=user=rca-admin --from-literal=password=rcaComplexPassword

# install root ca
helm upgrade --install --atomic --timeout 300s --wait-for-jobs install root-ca -n orderer helm-charts/fabric-ca -f examples/fabric-ca/root-ca.yaml

# create secret for TLS ca
kubectl -n orderer create secret generic tlsca-secret --from-literal=user=tls-admin --from-literal=password=TlsComplexPassword

# install tls ca
helm upgrade --install --atomic --timeout 300s --wait-for-jobs install tls-ca -n orderer helm-charts/fabric-ca -f examples/fabric-ca/tls-ca.yaml

# root ca identities
helm upgrade --install --atomic --timeout 300s --wait-for-jobs install rootca-ops -n orderer helm-charts/fabric-ops/ -f examples/fabric-ops/rootca/rootca-identities.yaml

# tls ca identities
helm upgrade --install --atomic --timeout 300s --wait-for-jobs install tlsca-ops -n orderer helm-charts/fabric-ops/ -f examples/fabric-ops/tlsca/tlsca-identities.yaml

# create secret for ica-orderer
kubectl -n orderer create secret generic orderer-secret --from-literal=user=ica-orderer --from-literal=password=icaordererSamplePassword

# orderer ica
helm upgrade --install --atomic --timeout 300s --wait-for-jobs install ica-orderer -n orderer helm-charts/fabric-ca -f examples/fabric-ca/ica-orderer.yaml

# create initialpeerorg ns
kubectl create ns initialpeerorg

# create secret for ica-initialpeerorg
kubectl -n initialpeerorg create secret generic initialpeerorg-secret --from-literal=user=ica-initialpeerorg --from-literal=password=icainitialpeerorgSamplePassword

# ica-initialpeer-org
helm upgrade --install --atomic --timeout 300s --wait-for-jobs install ica-initialpeerorg -n initialpeerorg helm-charts/fabric-ca -f examples/fabric-ca/ica-initialpeerorg.yaml

# register orderer identities
helm upgrade --install --atomic --timeout 300s --wait-for-jobs install orderer-ops -n orderer helm-charts/fabric-ops/ -f examples/fabric-ops/orderer/orderer-identities.yaml

# register initialpeerorg identities
helm upgrade --install --atomic --timeout 300s --wait-for-jobs install initialpeerorg-ops -n initialpeerorg helm-charts/fabric-ops/ -f examples/fabric-ops/initialpeerorg/identities.yaml

# Generate Genesisblock & Channel transaction file
helm upgrade --install --atomic --timeout 300s --wait-for-jobs install cryptogen -n orderer helm-charts/fabric-ops/ -f examples/fabric-ops/orderer/orderer-cryptogen.yaml

# deploy orderers
helm upgrade --install --atomic --timeout 300s --wait-for-jobs install orderer -n orderer helm-charts/fabric-orderer/ -f examples/fabric-orderer/orderer.yaml

# deploy initialpeerorg peers
helm upgrade --install --atomic --timeout 300s --wait-for-jobs install peer -n initialpeerorg helm-charts/fabric-peer/ -f examples/fabric-peer/initialpeerorg/values.yaml

# create channel
helm upgrade --install --atomic --timeout 300s --wait-for-jobs install channelcreate -n initialpeerorg helm-charts/fabric-ops/ -f examples/fabric-ops/initialpeerorg/channel-create.yaml

echo -e "\nend time: $(date '+%F %T')\n"