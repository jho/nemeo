#!/usr/bin/env bash

set -euo pipefail

for model in iam feeds ledger budgeting; do
  npx --yes @milehimikey/em@1.14.0 render \
    "docs/event-model/models/$model/$model.em" \
    -o "docs/event-model/models/$model/$model.svg"
done
