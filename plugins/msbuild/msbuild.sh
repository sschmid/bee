#!/usr/bin/env bash
#
# Author: @sschmid
# Build .NET apps

msbuild::_new() {
  echo "# msbuild"
  echo 'MSBUILD_SOLUTION="${PROJECT}.sln"'
}

msbuild::build() {
  local path
  if [[ $# -eq 1 ]]; then
    path="$1"
  else
    path="${MSBUILD_SOLUTION}"
  fi

  log_func "${path}"

  msbuild /p:Configuration=Release /v:m "${path}"
}

msbuild::debug_build() {
  local path
  if [[ $# -eq 1 ]]; then
    path="$1"
  else
    path="${MSBUILD_SOLUTION}"
  fi

  log_func "${path}"
  msbuild /p:Configuration=Debug /v:m "${path}"
}

msbuild::clean() {
  log_func
  msbuild /t:Clean /p:Configuration=Release /v:m "${MSBUILD_SOLUTION}"
}

msbuild::rebuild() {
  log_func
  msbuild::clean
  msbuild::build
}

msbuild::restore() {
  msbuild -t:restore "${MSBUILD_SOLUTION}"
}
