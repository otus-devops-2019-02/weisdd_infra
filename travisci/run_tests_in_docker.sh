#!/usr/bin/env bash
HOMEWORK_RUN=./travisci/tests/run_tests.sh

if [ -f $HOMEWORK_RUN ]; then
	echo "Run tests (linters, validators)"
	docker exec -e USER=appuser hw-test $HOMEWORK_RUN
else
	echo "We don't have any tests"
	exit 0
fi
