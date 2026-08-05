FROM ghcr.io/actions/actions-runner:latest

USER root

# image of the self hosted runners is different than the base image of GH's cloud runner
# install common dependencies. git, curl and jq is pre-installed in the image
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    python3 \
    gettext-base && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

USER runner
