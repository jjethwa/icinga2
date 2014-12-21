build: apache2_supervisor CONTRIB.md database-ido.xml Dockerfile Dockerfile-ubuntu fs-aio.conf icinga2.conf icinga2_supervisor innodb_override_aio.cnf LICENSE mysql_supervisor README.md run .last_built
	docker build -t dumolibr/icinga2 .|tee .last_build
	@grep "Successfully built" .last_build|awk '{print $$3}' >  .last_built && rm .last_build
last: .last_built
	LAST:=$(shell cat .last_built) 
	#echo $(LAST)
runit: .last_built
	docker run -t --privileged `cat .last_built`
logs: .last_built
	LAST=$$(cat .last_built)
	docker logs $(LAST)
test:
	VAR1 := $(shell echo $(SOME_VAR))
	VAR2 := $(shell echo $(VAR1))
stop:
	docker stop `cat .last_built`
