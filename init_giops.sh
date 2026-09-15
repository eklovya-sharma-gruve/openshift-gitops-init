#!/bin/bash

read -p "CLUSTER_ADMIN_USER: " CLUSTER_ADMIN_USER
read -s -p "CLUSTER_ADMIN_PASS: " CLUSTER_ADMIN_PASS
echo

# Login to cluster
oc login \
    -u "$CLUSTER_ADMIN_USER" \
    -p "$CLUSTER_ADMIN_PASS" \
    "https://api.${CLUSTER_NAME}.gruveai.com:6443"

echo "Installing Openshift GitOps Operator"
helm install gitops-operator ./argo-gitops-operator/

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to install GitOps Operator"
    exit 1
fi

echo "GitOps Operator Helm installation completed."
echo "Waiting for Argo CD CRDs to become available..."

# Wait for Application CRD
until oc get crd applications.argoproj.io >/dev/null 2>&1; do
    echo "Waiting for applications.argoproj.io CRD..."
    sleep 5
done

# Wait for AppProject CRD
until oc get crd appprojects.argoproj.io >/dev/null 2>&1; do
    echo "Waiting for appprojects.argoproj.io CRD..."
    sleep 5
done

echo "Argo CD CRDs are available."
echo "Configuring GitOps apps"

helm install gitops-init ./gitops-init/ \
    -f ./override/values_init.yaml \
    --set repoURL=https://github.com/eklovya-sharma-gruve/openshift-gitops-init.git

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to install gitops-init"
    exit 1
fi

echo "GitOps initialization completed successfully."
