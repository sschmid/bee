#!/usr/bin/env bash
#
# Author: @sschmid
# Build .NET apps

dotnet::_new() {
  echo '# dotnet
DOTNET_SOLUTION="${PROJECT}.sln"
'
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
