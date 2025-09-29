# Function that simplifies the terraform init command for a module in the kafka-shared-msk folder.
# Expects the environment variables to be set:
# - ENV: it is either `dev` or `prod`
# - REPO_ROOT: the root path where the kafka-cluster-config is checked out
tfinit() {
  module=$1

  cd "${REPO_ROOT}/${ENV}-aws/kafka-shared-msk/${module}" || return

  terraform init -reconfigure -upgrade
}
