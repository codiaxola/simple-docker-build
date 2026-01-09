# Copyright (C) 2025 Codiax Sweden AB
# SPDX-License-Identifier: GPL-2.0-or-later

define HELPTEXT =
  yocto-shell       - Launch an interactive shell with Yocto build environment.
                      This target can take an environment variable `cmd` as
                      argument with a command to execute in the shell.
  print-<VAR>       - Print the value of the variable VAR
endef

export HELPTEXT

.PHONY: help
help:
	@echo "$$HELPTEXT" | more

################################################################################
# Misc definitions
-include .config

TOPDIR=$(CURDIR)/

################################################################################
# Make utils

# V is used as a verbose option, to output commands
# Use on the command line:   make V=1 <target>
export V ?= 0
export Q := @
ifeq ($(V),1)
	Q :=
endif

# Print variable value
# Use on the command line:   make print-VARNAME
print-%: ; $(Q)echo $*=$($*)

################################################################################
# Docker
DOCKER_BUILD_IMAGE=codiax-docker-builder
DOCKERDIR=$(TOPDIR)/docker
DOCKERFILE=$(DOCKERDIR)/Dockerfile
DOCKER_HISTORY=$(CURDIR)/.docker_bash_history

# DOCKER_EXTRA_ARGS can be used for project makefiles to provide extra arguments
# to the docker run command
DOCKER_EXTRA_ARGS ?=

ifneq ($(SSH_AUTH_SOCK),)
SSH_AGENT_ARGS = --volume $(SSH_AUTH_SOCK):$(SSH_AUTH_SOCK) --env SSH_AUTH_SOCK
endif

# DOCKER_ID is a unique hash for the current Dockerfile and user
# It is used as a version tag for docker images and is useful to share docker
# base images built from the same version of the Dockerfile among different
# projects on the same host, by the same user
DOCKER_ID = $(shell echo $(CONFIG_EXTRA_DOCKER_PACKAGES) | cat $(DOCKERDIR)/* - | md5sum | cut -c 1-4)

# Dependencies needed to cleanly run the docker container
DOCKER_DEPS = $(DOCKER_BUILD_IMAGE) $(DOCKER_CLEAN_HASH) $(DOCKER_HISTORY) docker-prepare-volumes

# If these are created by the docker run command they will be owned by root.
# They need to be created beforehand to be owned by the user.
.PHONY: docker-prepare-volumes
docker-prepare-volumes:
	$(Q)mkdir -p $(HOME)/.ssh

# build docker image used for yocto based builds
.PHONY: $(DOCKER_BUILD_IMAGE)
$(DOCKER_BUILD_IMAGE):
	@if ! docker inspect $(DOCKER_BUILD_IMAGE):$(DOCKER_ID) >/dev/null 2>&1; then \
		docker build \
			--target $(DOCKER_BUILD_IMAGE) \
			--tag $(DOCKER_BUILD_IMAGE):$(DOCKER_ID) \
			$(DOCKERDIR) ; \
	fi

DOCKER_USER_MOUNTS ?= \
	--mount type=bind,source="$(DOCKER_HISTORY)",target="/home/user/.bash_history" \
	--volume $(HOME)/.ssh:/home/user/.ssh:ro \

DOCKER_CMD=docker run --tty --interactive --rm \
	--net host \
	$(SSH_AGENT_ARGS) \
	$(DOCKER_EXTRA_ARGS) \
	--workdir $(CURDIR) \
	$(DOCKER_USER_MOUNTS) \
	--volume $(CURDIR):$(CURDIR):rw \
	$(DOCKER_BUILD_IMAGE):$(DOCKER_ID)

$(DOCKER_HISTORY):
	$(Q)touch $(DOCKER_HISTORY)

clean-docker-history:
	$(Q)rm -f $(DOCKER_HISTORY)

# Bitbake builds in Docker containers do not always clean up completely.
# Remove file left behind.
DOCKER_CLEAN_HASH=docker-clean-hash
.PHONY: docker-clean-hash
docker-clean-hash:
	$(Q)rm -f $(TOPDIR)/build/hashserve.sock

.PHONY: clean-docker
clean-docker: $(DOCKER_CLEAN_HASH)
	$(Q)docker inspect $(DOCKER_BUILD_IMAGE):$(DOCKER_ID) >/dev/null 2>&1 \
		&& docker image rm -f $(DOCKER_BUILD_IMAGE):$(DOCKER_ID) || true


SHELLPROMPT ?= docker-shell:\\\w\$$

cmd ?= bash -rcfile <(echo PS1='$(SHELLPROMPT)\ ') -i
SHELL_CMD=$(DOCKER_CMD) bash -c \
	  "$(cmd)"


# Start bash terminal in docker
.PHONY: yocto-shell
yocto-shell: $(DOCKER_DEPS) 
	@echo "Starting an interactive shell"
	@echo "Press Ctrl-d or call 'exit' when finished"
	$(Q)$(SHELL_CMD) || exit

# Clean targets
.PHONY: distclean
distclean: clean-docker clean-docker-history
