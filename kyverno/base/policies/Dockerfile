FROM golang:alpine

RUN \
  apk add --no-cache gcc git make musl-dev \
  && git clone https://github.com/kyverno/kyverno \
  && cd kyverno \
  && make cli \
  && mv ./cmd/cli/kubectl-kyverno/kyverno /usr/local/bin/kyverno

CMD [ "/usr/local/bin/kyverno" ]
