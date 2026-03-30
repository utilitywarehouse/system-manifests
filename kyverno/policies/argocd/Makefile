.PHONY: test validate_policy apply-report diff-apply-report write-apply-report

YQ_FILTER = '.results[] |= (pick(["message", "policy", "result", "resources"]) | .resources[] |= pick(["name"])) | .results |= sort_by(.message, .resources[0].name)'

KYVERNO = reg.kyverno.io/kyverno/kyverno-cli:latest

# extract the resources from kyverno-test.yaml file
TEST_RESOURCES = $(shell yq '.resources[] | "test/"+.' test/kyverno-test.yaml | tr '\n' ',')

test:
	docker run --rm -v "${PWD}":"${PWD}" --workdir="${PWD}" ${KYVERNO} test ./test

validate_policy:
	@if [ -z "$$POLICY" ]; then \
		echo "Error: policy path/file not specified. Usage: make <target> POLICY=path/to/policy.yaml"; \
		exit 1; \
	fi;

# make apply-report POLICY=application-field-validation.yaml  
apply-report: validate_policy
	@docker run --rm -v "${PWD}":"${PWD}" --workdir="${PWD}" ${KYVERNO}\
		apply ${POLICY} \
		--resource=${TEST_RESOURCES} \
		--policy-report | yq ${YQ_FILTER}

write-apply-report: validate_policy
	@$(MAKE) -s apply-report > ./test/report/${POLICY}

# make diff-apply-report POLICY=application-field-validation.yaml
diff-apply-report: validate_policy
	@diff -u \
		--label "EXPECTED" <(yq -P 'sort_keys(..)' -o=props ./test/report/${POLICY}) \
		--label "ACTUAL"   <($(MAKE) -s apply-report | yq -P 'sort_keys(..)' -o=props)