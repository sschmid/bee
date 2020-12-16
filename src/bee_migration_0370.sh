#!/usr/bin/env bash
# Dec 2020

if [[ -f bee.sh ]]; then
  echo "WARNING: bee.sh is deprecated."
  echo "Please see CHANGELOG.md and apply the required actions!"
  source bee.sh
  BEE_PROJECT="${PROJECT}"
  BEE_RESOURCES="${RESOURCES}"
fi
