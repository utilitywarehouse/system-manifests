#!/bin/sh

set -e

# Install kubectl
KUBECTL_VERSION="${KUBECTL_VERSION:-"$(wget -O - \
  https://storage.googleapis.com/kubernetes-release/release/stable.txt)"}"
wget -O /usr/local/bin/kubectl \
  "https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
chmod +x /usr/local/bin/kubectl

# Create the reload script. This script will patch the docker-registry
# deployment's pod template with an annotation containing the sha of the
# certificate, which will trigger a restart if the sha has changed.
echo '#!/bin/sh
set -e
if [ "$#" -eq 3 ] && [ "$3" == "..data" ]; then
  sha=$(cat /etc/tls/tls.crt | sha256sum | awk '"'"'{print $1}'"'"')
  kubectl patch deployment docker-registry \
    -p "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"uw.systems/registry-auth-cert\":\"${sha}\"}}}}}"
  kubectl rollout status deployment/docker-registry
fi' > /reload && chmod +x /reload

# Run the reload script once. This will catch cases where the certificate
# changed while this script wasn't running.
/reload "y" "/etc/tls" "..data"

# Run the reload script when /etc/tls is updated
inotifyd /reload /etc/tls:y