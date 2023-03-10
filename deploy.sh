#!/bin/bash
set +e
flyctl secrets set AWS_SECRET_ACCESS_KEY=$(terraform output -raw accesskeysecret) LITESTREAM_SECRET_ACCESS_KEY=$(terraform output -raw accesskeysecret)
set -e
flyctl deploy --json --force-machines --auto-confirm --verbose
set +e
flyctl machine status $(flyctl m list --json| jq -r .[].id) | grep -i Memory | grep $(terraform output --raw memory) 2>&1 > /dev/null
if [ $? -ne 0 ]
then
  set -e
  flyctl machine update $(flyctl m list --json| jq -r .[].id) --memory $(terraform output --raw memory) --yes
fi
