#!/bin/bash

echo "Cleaning up..."

helm delete -n initialpeerorg $(helm list -n initialpeerorg --short)
helm delete -n orderer $(helm list -n orderer --short)

kubectl delete ns initialpeerorg
kubectl delete ns orderer

helm delete -n filestore $(helm list -n filestore --short)
kubectl delete ns filestore

echo "Done!"