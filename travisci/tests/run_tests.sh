#!/usr/bin/env bash
set -e

# Creating dummy keys for terraform linter
touch ~/.ssh/appuser.pub ~/.ssh/appuser

# Install requirements
cd ansible && ansible-galaxy install -r environments/stage/requirements.yml && cd ..

inspec exec travisci/tests/
