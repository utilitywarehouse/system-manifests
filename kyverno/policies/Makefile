SHELL := /bin/bash

.PHONY: build test

build:
	docker build -t kyverno-test .

test: build
	docker run -v "${PWD}":"${PWD}" --workdir="${PWD}" kyverno-test kyverno test ./../../

gen: build
	docker run -v "${PWD}":"${PWD}" --workdir="${PWD}" kyverno-test kyverno apply pods/replace-annotation.yaml --resource pods/test/test-replace-annotation.yaml --output gen