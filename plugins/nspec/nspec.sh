#!/usr/bin/env bash
#
# Author: @sschmid
# Build and run nspec tests

nspec::_new() {
  echo '# nspec => dotnet
NSPEC_TESTS_PROJECT=Tests/Tests.sln
NSPEC_TESTS_RUNNER=Tests/bin/Release/Tests.exe'
}

nspec::run() {
  log_func
  dotnet::build "${NSPEC_TESTS_PROJECT}"
  mono "${NSPEC_TESTS_RUNNER}" "$@"
}
