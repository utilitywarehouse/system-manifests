FROM alpine:3.19

# Install dependencies and Docker CLI
RUN apk add --no-cache bash curl git docker-cli

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/

# Install kustomize
ENV KUSTOMIZE_VERSION=v5.7.1
RUN curl -Ls https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz \
    | tar xz -C /usr/local/bin kustomize

# Install kind
RUN curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64 \
    && chmod +x ./kind \
    && mv ./kind /usr/local/bin/kind

# Install Chainsaw
# ENV CHAINSAW_VERSION="v0.2.14"
# RUN curl -LO "https://github.com/kyverno/chainsaw/releases/download/${CHAINSAW_VERSION}/chainsaw_linux_amd64.tar.gz" \
#     | tar xz -C /usr/local/bin chainsaw

# Install latest Chainsaw
RUN curl -sSL https://github.com/kyverno/chainsaw/releases/latest/download/chainsaw_linux_amd64.tar.gz \
    | tar xz -C /usr/local/bin chainsaw

WORKDIR /repo
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
