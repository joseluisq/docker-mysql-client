build:
	@docker build -t mysql-client:latest -f 8.0/Dockerfile .
.PHONY: build

HOME_USER ?= $(shell echo $$(id -u $$USER):$$(id -g $$USER))

export:
	@docker run --rm -it \
		--user $(HOME_USER) \
		--volume $(PWD):/home/mysql/sample \
		--network mysql8_net \
		--workdir /home/mysql/sample \
			mysql-client:latest \
			mysql_exporter export.env
.PHONY: export

import:
	@docker run --rm -it \
		--user $(HOME_USER) \
		--volume $(PWD):/home/mysql/sample \
		--network mysql8_net \
		--workdir /home/mysql/sample \
			mysql-client:latest \
			mysql_importer import.env
.PHONY: import
