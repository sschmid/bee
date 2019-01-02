#!/usr/bin/env bash
#
# Author: @sschmid
# Build .NET apps

msbuild::_new() {
  echo '# msbuild
MSBUILD_SOLUTION="${PROJECT}.sln"
'
}

msbuild::build() {
  local path
  if [[ $# -eq 1 ]]; then
    path="$1"
  else
    path="${MSBUILD_SOLUTION}"
  fi

  log_func "${path}"
  msbuild /property:Configuration=Release /verbosity:minimal "${path}"
}

msbuild::clean() {
  log_func
  msbuild /target:Clean /property:Configuration=Release /verbosity:minimal "${MSBUILD_SOLUTION}"
}

msbuild::rebuild() {
  log_func
  msbuild::clean
  msbuild::build
}
