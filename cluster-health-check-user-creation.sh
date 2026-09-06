#!/bin/bash
set -euo pipefail

# Read required variables
read -p "Cluster name: " CLUSTER_NAME
read -p "Kubeconfig path: " KUBECONFIG_PATH
read -s -p "Kubeadmin password: " KUBEADMIN_PASS
echo

# Check required variables
if [[ -z "$CLUSTER_NAME" || -z "$KUBEADMIN_PASS" ]]; then
    echo "Values not set, try again after setting all required values."
    exit 1
fi

# Login to cluster
oc login \
    -u kubeadmin \
    -p "$KUBEADMIN_PASS" \
    "https://api.${CLUSTER_NAME}.gruveai.com:6443"

# Check nodes
echo "Checking node health..."

if ! oc wait --for=condition=Ready nodes --all --timeout=5m; then
    echo "ERROR: One or more nodes are not Ready"
    oc get nodes -o wide
    exit 1
fi

echo "All nodes are Ready"
oc get nodes -o wide

# Check ClusterOperators
oc get co

# Check MachineConfigPools
echo "Checking MachineConfigPools..."

if ! oc wait --for=condition=Updated mcp --all --timeout=10m; then
    echo "ERROR: MachineConfigPools are not updated"
    oc get mcp
    exit 1
fi

echo "MachineConfigPools are healthy"
oc get mcp

echo "Let's create htpasswd file"

read -p "HTPasswd file name: " HTPASSWD_FILE
read -p "Cluster admin username: " CLUSTER_ADMIN_USER

htpasswd -B -c "${HTPASSWD_FILE}.htpasswd" "$CLUSTER_ADMIN_USER"

echo "Creating a secret in openshift-config namespace from htpasswd file"

read -p "Secret name: " SECRET_NAME

oc create secret generic "$SECRET_NAME" \
    --from-file=htpasswd="${HTPASSWD_FILE}.htpasswd" \
    -n openshift-config

echo "Let's create OAuth CR"

read -p "Login title: " LOGIN_TITLE

# Update OAuth CR
sed -i "9s/name: .*/name: ${SECRET_NAME}/" .oauth-cr.yaml
sed -i "11s/name: .*/name: ${LOGIN_TITLE}/" .oauth-cr.yaml

# Apply OAuth CR
oc apply -f .oauth-cr.yaml

echo "Giving user cluster-admin access"

oc adm policy add-cluster-role-to-user cluster-admin "$CLUSTER_ADMIN_USER"

echo "Successfully created cluster admin user"
