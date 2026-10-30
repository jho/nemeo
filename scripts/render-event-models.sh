#!/usr/bin/env bash

set -euo pipefail

for model in iam feeds ledger budgeting; do
  npm exec --yes --package @milehimikey/em@1.14.0 -- em render \
    "docs/event-model/models/$model/$model.em" \
    -o "docs/event-model/models/$model/$model.svg"
done
