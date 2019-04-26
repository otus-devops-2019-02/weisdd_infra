#!/usr/bin/env bash
set -e

# Install requirements
cd ansible && ansible-galaxy install -r environments/stage/requirements.yml && cd ..

inspec exec travisci/tests/
