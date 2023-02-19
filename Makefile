.SILENT:
.PHONY: 

help:
	{ grep --extended-regexp '^[a-zA-Z_-]+:.*#[[:space:]].*$$' $(MAKEFILE_LIST) || true; } \
	| awk 'BEGIN { FS = ":.*#[[:space:]]*" } { printf "\033[1;32m%-28s\033[0m%s\n", $$1, $$2 }'

env-create: # 1) create .env file
	./make.sh env-create

terraform-init: # 2) terraform init (upgrade) + validate
	./make.sh terraform-init

infra-create: # 2) terraform create sns topic + ssh key + iam user ...
	./make.sh infra-create

vagrant-up: # 3) create monitoring + node1 + node2
	./make.sh vagrant-up

vagrant-halt: # 3) halt the 3 machines
	./make.sh vagrant-halt

ansible-play: # 4) install + configure prometheus + grafana + alert manager ...
	./make.sh ansible-play

vagrant-destroy: # 5) destroy the 3 machines
	./make.sh vagrant-destroy

infra-destroy: # 5) terraform destroy sns topic + ssh key + iam user ...
	./make.sh infra-destroy
