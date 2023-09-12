docker:
	DOCKER_BUILDKIT=1 \
	docker build \
	--platform=linux/amd64 \
	--build-arg BUILDKIT_INLINE_CACHE=1 \
	--target=installed \
	-f Dockerfile \
	-t mrefish/onefish:installed \
	.

dev:
	DOCKER_BUILDKIT=1 \
	docker run \
	--rm \
	-it \
	--platform=linux/amd64 \
	--entrypoint /bin/bash \
	mrefish/onefish:installed

broken:
	DOCKER_BUILDKIT=1 \
	docker build \
	--platform=linux/amd64 \
	--build-arg BUILDKIT_INLINE_CACHE=1 \
	--target=broken \
	-f Dockerfile \
	-t mrefish/onefish:broken \
	.
