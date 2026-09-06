#!/bin/bash

echo "Installing Openshift GitOps Operator"
helm install gitops-operator ./argo-gitops-operator/ 

echo "Configuring Gitops apps of app"
helm install gitops-init ./gitops-init/ -f ./override/values_init.yaml --set repoURL=https://github.com/eklovya-sharma-gruve/openshift-gitops-init.git

