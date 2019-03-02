#!/usr/bin/env bash
#
# Author: @sschmid
# Build and run nspec tests

nspec::_new() {
  echo "# nspec => $(nspec::_deps)"
  echo 'NSPEC_TESTS_PROJECT=Tests/Tests.sln
NSPEC_TESTS_RUNNER=Tests/bin/Release/Tests.exe'
}

nspec::_deps() {
  echo "msbuild"
}

nspec::run() {
  log_func
  msbuild::build "${NSPEC_TESTS_PROJECT}"
  mono "${NSPEC_TESTS_RUNNER}" "$@"
}
