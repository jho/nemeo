#!/usr/bin/env bash

set -euo pipefail

for model in iam feeds ledger budgeting; do
  model_file="docs/event-model/models/$model/$model.em"
  model_dir="docs/event-model/models/$model"

  ./node_modules/.bin/em render \
    "$model_file" \
    -o "$model_dir/$model.svg"

  for slice_doc in "$model_dir"/slices/*.md; do
    [ -e "$slice_doc" ] || continue

    slice_key="$(basename "$slice_doc" .md)"
    slice_name="$(sed -n 's/^# Slice: //p' "$slice_doc")"
    [ -n "$slice_name" ] || continue

    ./node_modules/.bin/em render \
      "$model_file" \
      --slice "$slice_name" \
      -o "$model_dir/slices/$slice_key.svg"
  done
done
