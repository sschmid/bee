#!/usr/bin/env bash
#
# Author: @sschmid
# Build and test .NET apps

dotnet::_new() {
  echo '# dotnet
DOTNET_SOLUTION="${PROJECT}.sln"
DOTNET_TESTS_PROJECT=Tests/Tests.sln
DOTNET_TESTS_RUNNER=Tests/bin/Release/Tests.exe'
}

dotnet::build() {
  local path
  if [[ $# -eq 1 ]]; then
    path="$1"
  else
    path="${DOTNET_SOLUTION}"
  fi

  log_func "${path}"
  msbuild /property:Configuration=Release /verbosity:minimal "${path}"
}

dotnet::clean() {
  log_func
  msbuild /target:Clean /property:Configuration=Release /verbosity:minimal "${DOTNET_SOLUTION}"
}

dotnet::rebuild() {
  log_func
  dotnet::clean
  dotnet::build
}

dotnet::build_tests() {
  dotnet::build "${DOTNET_TESTS_PROJECT}"
}

dotnet::run_tests() {
  log_func
  mono "${DOTNET_TESTS_RUNNER}" "$@"
}

dotnet::tests() {
  log_func
  dotnet::build_tests
  dotnet::run_tests "$@"
}
