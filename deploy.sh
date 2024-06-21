#!/bin/bash

printf "\nInitiating deployment\n"

echo -e "\nstart time: $(date '+%F %T')\n"
starttime=$(date +%s%N)

cc_name="basic-chaincode_go_1.0.tar.gz"

# install filestore.
printf "Deploying Filestore server\n\n"
helm upgrade --install --atomic --timeout 300s --wait-for-jobs filestore -n filestore helm-charts/filestore/ -f examples/filestore/values.yaml --create-namespace

printf "\nDeployed Filestore, printing logs...\n\n"
filestore_pod=$(kubectl get pods -n filestore -l app.kubernetes.io/name=filestore -o jsonpath="{.items[*].metadata.name}")
kubectl logs -n filestore "$filestore_pod"

# create orderer NS
printf "\nCreating Orderer namespace\n\n"
kubectl create ns orderer

# create secret for Root CA
printf "\nCreating Root CA secrets\n\n"
kubectl -n orderer create secret generic rca-secret --from-literal=user=rca-admin --from-literal=password=rcaComplexPassword

# install root ca
printf "\nDeploying Root CA\n\n"
helm upgrade --install --atomic --timeout 300s --wait-for-jobs root-ca -n orderer helm-charts/fabric-ca -f examples/fabric-ca/root-ca.yaml

printf "\nDeployed Root CA, printing logs...\n\n"
root_ca_pod=$(kubectl get pods -n orderer -l app.kubernetes.io/name=root-ca -o jsonpath="{.items[*].metadata.name}")
kubectl logs -n orderer "$root_ca_pod"

# create secret for TLS ca
printf "\nCreating TLS CA secrets\n\n"
kubectl -n orderer create secret generic tlsca-secret --from-literal=user=tls-admin --from-literal=password=TlsComplexPassword

# install tls ca
printf "\nDeploying TLS CA\n\n"
helm upgrade --install --atomic --timeout 300s --wait-for-jobs tls-ca -n orderer helm-charts/fabric-ca -f examples/fabric-ca/tls-ca.yaml

printf "\nDeployed TLS CA, printing logs...\n\n"
tls_ca_pod=$(kubectl get pods -n orderer -l app.kubernetes.io/name=tls-ca -o jsonpath="{.items[*].metadata.name}")
kubectl logs -n orderer "$tls_ca_pod"

# root ca identities
printf "\nRegistering Orderer ICA and Org1 ICA identities with Root CA\n\n"
helm upgrade --install --atomic --timeout 300s --wait-for-jobs rootca-ops -n orderer helm-charts/fabric-ops/ -f examples/fabric-ops/rootca/rootca-identities.yaml

printf "\nRegistered Orderer ICA and Org1 ICA identities with Root CA, printing logs...\n\n"
rca_ica_ord_reg=$(kubectl get pods -n orderer -l job-name=rootca-ops-ica-orderer-registration -o jsonpath="{.items[*].metadata.name}")
kubectl logs -n orderer "$rca_ica_ord_reg"
printf "\n\n"
rca_ica_org1_reg=$(kubectl get pods -n orderer -l job-name=rootca-ops-ica-org1-registration -o jsonpath="{.items[*].metadata.name}")
kubectl logs -n orderer "$rca_ica_org1_reg"

# tls ca identities
printf "\nRegistering Orderer and Org1 Peer identities with TLS CA\n\n"
helm upgrade --install --atomic --timeout 300s --wait-for-jobs tlsca-ops -n orderer helm-charts/fabric-ops/ -f examples/fabric-ops/tlsca/tlsca-identities.yaml

printf "\nRegistered Orderer and Org1 Peer identities with TLS CA, printing logs...\n\n"
tls_ord0_reg=$(kubectl get pods -n orderer -l job-name=tlsca-ops-orderer0-orderer-registration -o jsonpath="{.items[*].metadata.name}")
kubectl logs -n orderer "$tls_ord0_reg"
printf "\n\n"
tls_org1_peer0_reg=$(kubectl get pods -n orderer -l job-name=tlsca-ops-peer0-org1-registration -o jsonpath="{.items[*].metadata.name}")
kubectl logs -n orderer "$tls_org1_peer0_reg"

# create secret for ica-orderer
printf "\nCreating Orderer ICA secrets\n\n"
kubectl -n orderer create secret generic orderer-secret --from-literal=user=ica-orderer --from-literal=password=icaordererSamplePassword

# orderer ica
printf "\nDeploying Orderer ICA\n\n"
helm upgrade --install --atomic --timeout 300s --wait-for-jobs ica-orderer -n orderer helm-charts/fabric-ca -f examples/fabric-ca/ica-orderer.yaml

printf "\nDeployed Orderer ICA, printing logs...\n\n"
ord_ica_pod=$(kubectl get pods -n orderer -l app.kubernetes.io/name=ica-orderer -o jsonpath="{.items[*].metadata.name}")
kubectl logs -n orderer "$ord_ica_pod"

# create org1 ns
printf "\nCreating Org1 namespace\n\n"
kubectl create ns org1

# create secret for ica-org1
printf "\nCreating Org1 ICA secrets\n\n"
kubectl -n org1 create secret generic org1-secret --from-literal=user=ica-org1 --from-literal=password=icaorg1SamplePassword

# ica-org1
printf "\nDeploying Org1 ICA\n\n"
helm upgrade --install --atomic --timeout 300s --wait-for-jobs ica-org1 -n org1 helm-charts/fabric-ca -f examples/fabric-ca/ica-org1.yaml

printf "\nDeployed Org1 ICA, printing logs...\n\n"
org1_ica_pod=$(kubectl get pods -n org1 -l app.kubernetes.io/name=ica-org1 -o jsonpath="{.items[*].metadata.name}")
kubectl logs -n org1 "$org1_ica_pod"

# register orderer identities
printf "\nRegistering Orderer and Orderer Admin identities with Orderer ICA\n\n"
helm upgrade --install --atomic --timeout 300s --wait-for-jobs orderer-ops -n orderer helm-charts/fabric-ops/ -f examples/fabric-ops/orderer/orderer-identities.yaml

printf "\nRegistered Orderer and Orderer Admin identities with Orderer ICA, printing logs...\n\n"
ord_admin_reg=$(kubectl get pods -n orderer -l job-name=orderer-ops-admin-registration -o jsonpath="{.items[*].metadata.name}")
kubectl logs -n orderer "$ord_admin_reg"
printf "\n\n"
ord0_ica_reg=$(kubectl get pods -n orderer -l job-name=orderer-ops-orderer0-orderer-registration -o jsonpath="{.items[*].metadata.name}")
kubectl logs -n orderer "$ord0_ica_reg"

# register org1 identities
printf "\nRegistering Org1 Admin and Peer identities with Org1 ICA\n\n"
helm upgrade --install --atomic --timeout 300s --wait-for-jobs org1-ops -n org1 helm-charts/fabric-ops/ -f examples/fabric-ops/org1/identities.yaml

printf "\nRegistered Org1 Admin and Peer identities with Org1 ICA, printing logs...\n\n"
org1_admin_reg=$(kubectl get pods -n org1 -l job-name=org1-ops-admin-registration -o jsonpath="{.items[*].metadata.name}")
kubectl logs -n org1 "$org1_admin_reg"
printf "\n\n"
org1_peer0_ica_reg=$(kubectl get pods -n org1 -l job-name=org1-ops-peer0-org1-registration -o jsonpath="{.items[*].metadata.name}")
kubectl logs -n org1 "$org1_peer0_ica_reg"

# Generate Genesisblock & Channel transaction file
printf "\nGenerating Genesis block and Channel transaction file\n\n"
helm upgrade --install --atomic --timeout 300s --wait-for-jobs cryptogen -n orderer helm-charts/fabric-ops/ -f examples/fabric-ops/orderer/orderer-cryptogen.yaml

printf "\nGenerated Genesis block and Channel transaction file, printing logs...\n\n"
ord_cryptogen=$(kubectl get pods -n orderer -l job-name=cryptogen-orderer -o jsonpath="{.items[*].metadata.name}")
kubectl logs -n orderer "$ord_cryptogen"

# deploy orderers
printf "\nDeploying Orderers\n\n"
helm upgrade --install --atomic --timeout 300s --wait-for-jobs orderer -n orderer helm-charts/fabric-orderer/ -f examples/fabric-orderer/orderer.yaml

printf "\nDeployed Orderes, printing logs...\n\n"
ord0_pod=$(kubectl get pods -n orderer -l app=orderer0-orderer -o jsonpath="{.items[*].metadata.name}")
kubectl logs -n orderer "$ord0_pod"

# deploy org1 peers
printf "\nDeploying Org1 Peers\n\n"
helm upgrade --install --atomic --timeout 300s --wait-for-jobs peer -n org1 helm-charts/fabric-peer/ -f examples/fabric-peer/org1/values.yaml

printf "\nDeployed Peers, printing logs...\n\n"
org1_peer0_pod=$(kubectl get pods -n org1 -l app=peer0-org1 -o jsonpath="{.items[*].metadata.name}")
kubectl logs -n org1 "$org1_peer0_pod" -c peer

# create channel
printf "\nCreating Channel\n\n"
helm upgrade --install --atomic --timeout 300s --wait-for-jobs channelcreate -n org1 helm-charts/fabric-ops/ -f examples/fabric-ops/org1/channel-create.yaml

printf "\nChannel created, printing logs...\n\n"
org1_chn_pod=$(kubectl get pods -n org1 -l job-name=channelcreate-org1 -o jsonpath="{.items[*].metadata.name}")
kubectl logs -n org1 "$org1_chn_pod"

# update anchor peer
printf "\nUpdating Org1 Anchor Peer\n\n"
helm upgrade --install --atomic --timeout 300s --wait-for-jobs updateanchorpeer -n org1 helm-charts/fabric-ops/ -f examples/fabric-ops/org1/update-anchor-peer.yaml

printf "\nUpdated Anchor Peer, printing logs...\n\n"
org1_anch_peer_pod=$(kubectl get pods -n org1 -l job-name=updateanchorpeer-org1-rev-1 -o jsonpath="{.items[*].metadata.name}")
kubectl logs -n org1 "$org1_anch_peer_pod"

# copy chaincode
printf "\nCopying Chaincode to Filestore\n"
kubectl cp examples/files/$cc_name filestore/"$filestore_pod":/usr/share/nginx/html/yourproject/$cc_name

# install chaincode
printf "\nInstalling Chaincode on Org1 Peers\n\n"
helm upgrade --install --atomic --timeout 300s --wait-for-jobs installchaincode -n org1 helm-charts/fabric-ops/ -f examples/fabric-ops/org1/install-chaincode.yaml

printf "\nInstalled Chaincode on Org1 Peers, printing logs...\n\n"
org1_ccinst_reg=$(kubectl get pods -n org1 -l job-name=installchaincode-org1-rev-1-peer0-org1 -o jsonpath="{.items[*].metadata.name}")
kubectl logs -n org1 "$org1_ccinst_reg"

echo -e "\nend time: $(date '+%F %T')\n"
endtime=$(date +%s%N)

diff=$((endtime-starttime))

printf "Time elapsed: %s.%s seconds\n" "${diff:0: -9}" "${diff: -9:3}"

printf "\nDone!\n"