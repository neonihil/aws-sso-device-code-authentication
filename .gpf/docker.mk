# -----------------------------------------------------------------------------
# description: Generic Docker Image Targets
# licence: LGPL3 <https://opensource.org/licenses/GPL3>
# author: Daniel Kovacs <mondomhogynincsen@gmail.com>
# version: 0.1
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# docker config
# -----------------------------------------------------------------------------

export DOCKER_IMAGE_FQN=$(DOCKER_IMAGE_REPOSITORY)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)
export DOCKER_BUILD_EXECUTABLE=$(PACKAGE_NAME)
export DOCKER_RUN_ENVIRONMENT=
export DOCKER_RUN_OPTIONS=
export DOCKER_BUILD_OPTIONS=

# -----------------------------------------------------------------------------
# docker-image::
# -----------------------------------------------------------------------------

docker-image::
		# --build-arg PYTHON_INSTALLER=$(DIST_FILE)
	docker build \
		--tag $(DOCKER_IMAGE_FQN) \
		--build-arg DOCKER_BUILD_EXECUTABLE=$(DOCKER_BUILD_EXECUTABLE) \
		$(DOCKER_BUILD_OPTIONS) \
		.


# -----------------------------------------------------------------------------
# docker-shell::
# -----------------------------------------------------------------------------

docker-shell::
	docker run \
		-it \
		$(DOCKER_RUN_ENVIRONMENT) \
		$(DOCKER_RUN_OPTIONS) \
		$(DOCKER_IMAGE_FQN) \
		/bin/sh


# -----------------------------------------------------------------------------
# docker-run::
# -----------------------------------------------------------------------------

docker-run::
	docker run \
		-it \
		$(DOCKER_RUN_ENVIRONMENT) \
		$(DOCKER_RUN_OPTIONS) \
		$(DOCKER_IMAGE_FQN)



# -----------------------------------------------------------------------------
# docker-push::
# -----------------------------------------------------------------------------

docker-push::
	docker push $(DOCKER_IMAGE_FQN)

