#!/bin/bash

TEST_TARGET=${1:-"kyverno/policies"}
CLUSTER_NAME="chainsaw-test-cluster"

INTERNAL_KUBECONFIG="/tmp/kubeconfig"
export KUBECONFIG="$INTERNAL_KUBECONFIG"

# 1. Handle explicit manual cleanup
if [ "$TEST_TARGET" = "clean" ]; then
    echo "🧹 Manually destroying the persistent cluster..."
    kind delete cluster --name "$CLUSTER_NAME"
    exit 0
fi

echo "Setting up test environment..."

# 2. Set up the trap based on the REUSE_CLUSTER flag
if [ "$REUSE_CLUSTER" = "true" ]; then
    trap 'echo "⏭️  REUSE_CLUSTER is active. Leaving cluster running for next time."' EXIT
else
    trap 'echo "🧹 Cleaning up..."; kind delete cluster --name "$CLUSTER_NAME"; echo "Cleanup complete!"' EXIT
fi

# 3. Create cluster ONLY if it doesn't already exist
if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    echo "Cluster '$CLUSTER_NAME' already exists! Skipping creation."
    CLUSTER_JUST_CREATED=false
else
    echo "Creating kind cluster: $CLUSTER_NAME..."
    kind create cluster --name "$CLUSTER_NAME"
    CLUSTER_JUST_CREATED=true
fi

# Generate Kubeconfig
kind get kubeconfig --internal --name "$CLUSTER_NAME" > "$INTERNAL_KUBECONFIG"

# 5. Install Kyverno and dependencies ONLY if we just created a fresh cluster
if [ "$CLUSTER_JUST_CREATED" = "true" ]; then
    echo "Waiting for kind nodes to be ready..."
    kubectl wait --for=condition=Ready nodes --all --timeout=120s

    echo "Installing Kyverno..."
    kubectl create -f https://github.com/kyverno/kyverno/raw/main/config/install-latest-testing.yaml

    echo "Waiting for Kyverno to be ready..."
    kubectl wait --namespace kyverno --for=condition=ready pod --all --timeout=120s
else
    echo "Skipping Kyverno installation (reusing existing cluster environment)."
fi

CHAINSAW_ARGS=("/repo/$TEST_TARGET" "--config" "/repo/kyverno/policies/.chainsaw.yaml")

if [ "$SKIP_DELETE" = "true" ]; then
    echo "🛑 SKIP_DELETE is active: Chainsaw will leave test resources in the cluster."
    CHAINSAW_ARGS+=("--skip-delete")
fi

echo "Running Chainsaw tests against: $TEST_TARGET"
chainsaw test "${CHAINSAW_ARGS[@]}"
