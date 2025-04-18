#!/bin/bash

# Script to create uipathadmin service account and generate kubeconfig
# This script requires 'oc' CLI to be installed and user to be logged in

set -e

# Function to display usage
usage() {
    echo "Usage: $0 -n <namespace> [-d]"
    echo "  -n    Namespace where service account will be created"
    echo "  -d    Enable debug mode"
    echo "  -h    Display this help message"
    exit 1
}

# Parse command line arguments
while getopts "n:dh" opt; do
    case ${opt} in
        n )
            NAMESPACE=$OPTARG
            ;;
        d )
            DEBUG_MODE=true
            ;;
        h )
            usage
            ;;
        \? )
            usage
            ;;
    esac
done

# Enable debug mode if flag is set
if [ "$DEBUG_MODE" = true ]; then
    set -x
fi

# Validate required arguments
if [ -z "$NAMESPACE" ]; then
    echo "Error: Namespace (-n) is required"
    usage
fi

echo "Creating service account in namespace: $NAMESPACE"
if [ "$DEBUG_MODE" = true ]; then
    echo "Debug Mode: enabled"
fi

# Create namespace if it doesn't exist
oc get namespace $NAMESPACE || oc new-project $NAMESPACE

# Set the namespace as default
oc project $NAMESPACE

# Create service account
echo "Creating service account: uipathadmin"
oc create serviceaccount uipathadmin

# Create rolebinding for admin permissions
echo "Creating rolebinding for admin permissions"
oc create rolebinding uipathadmin --clusterrole=admin --serviceaccount=$NAMESPACE:uipathadmin

# Generate kubeconfig
echo "Generating kubeconfig file..."

# Create token
TOKEN=$(oc -n $NAMESPACE create token uipathadmin --duration=8760h)

# Get API server URL
SERVER=$(oc config view -o jsonpath="{.clusters[].cluster.server}")

# Create kubeconfig file
echo "Creating kubeconfig file: uipathadminkubeconfig"
oc login --server=$SERVER --token=$TOKEN --kubeconfig=uipathadminkubeconfig --insecure-skip-tls-verify=true

# Disable debug mode if it was enabled
if [ "$DEBUG_MODE" = true ]; then
    set +x
fi

echo "Successfully created:"
echo "1. Namespace: $NAMESPACE"
echo "2. ServiceAccount: uipathadmin"
echo "3. RoleBinding: uipathadmin"
echo "4. Kubeconfig file: uipathadminkubeconfig"