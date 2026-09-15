#!/bin/bash

read -p "CLUSTER_ADMIN_USER: " CLUSTER_ADMIN_USER
read -p "CLUSTER_ADMIN_PASS: " CLUSTER_ADMIN_PASS
# Login to cluster
oc login \
    -u "$CLUSTER_ADMIN_USER" \
    -p "$CLUSTER_ADMIN_PASS" \
    "https://api.${CLUSTER_NAME}.gruveai.com:6443"

echo "Installing Openshift GitOps Operator"
helm install gitops-operator ./argo-gitops-operator/ 

echo "Configuring Gitops apps of app"
helm install gitops-init ./gitops-init/ -f ./override/values_init.yaml --set repoURL=https://github.com/eklovya-sharma-gruve/openshift-gitops-init.git

