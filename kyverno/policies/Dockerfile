FROM alpine:latest

RUN apk --no-cache add curl tar

ENV VERSION=v1.13.0

RUN curl -LO https://github.com/kyverno/kyverno/releases/download/${VERSION}/kyverno-cli_${VERSION}_linux_x86_64.tar.gz && \
    tar -xvf kyverno-cli_${VERSION}_linux_x86_64.tar.gz && \
    cp kyverno /usr/local/bin/

CMD [ "/usr/local/bin/kyverno" ]
