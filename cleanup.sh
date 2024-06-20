#!/bin/bash

echo "Cleaning up..."

helm delete -n org1 $(helm list -n org1 --short)
helm delete -n orderer $(helm list -n orderer --short)

kubectl delete ns org1
kubectl delete ns orderer

helm delete -n filestore $(helm list -n filestore --short)
kubectl delete ns filestore

echo "Done!"