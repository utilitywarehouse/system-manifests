# version managed by `make runner-image-version`.
FROM ghcr.io/actions/actions-runner:2.336.0

USER root

# image of the self hosted runners is different than the base image of GH's cloud runner
# install common dependencies. git, curl and jq is pre-installed in the image
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    python3 \
    gettext-base \
    curl \
    ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


# Node just to invoke playwright's CLI — version irrelevant to which OS deps get installed.
# 'npx playwright install' is not ran as every version has diff browsers and it adds 1.3GB
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    npm install -g corepack && \
    npx --yes playwright install-deps && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

USER runner
