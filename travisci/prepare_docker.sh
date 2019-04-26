#!/usr/bin/env bash
GROUP=2019-02
BRANCH=${TRAVIS_PULL_REQUEST_BRANCH:-$TRAVIS_BRANCH}
HOMEWORK_RUN=./travisci/tests/run_tests.sh
DOCKER_IMAGE=express42/otus-homeworks

echo HOMEWORK:$BRANCH

tree

if [ -f $HOMEWORK_RUN ]; then
	echo "Run tests"
	# Prepare network & run container
	docker network create hw-test-net
	docker run -d -v $(pwd):/srv -v /var/run/docker.sock:/tmp/docker.sock \
		-e DOCKER_HOST=unix:///tmp/docker.sock --cap-add=NET_ADMIN -p 33433:22 --privileged \
		--device /dev/net/tun --name hw-test --network hw-test-net $DOCKER_IMAGE
	# Show versions & run tests
	docker exec hw-test bash -c 'echo -=Get versions=-; ansible --version; ansible-lint --version; packer version; terraform version; tflint --version; docker version; docker-compose --version'
	docker exec -e USER=appuser -e BRANCH=$BRANCH hw-test $HOMEWORK_RUN
else
	echo "We don't have any tests"
	exit 0
fi
