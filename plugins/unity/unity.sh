#!/usr/bin/env bash
#
# Author: @sschmid
# Execute methods in Unity

unity::_new() {
  echo "# unity"
  echo 'UNITY_PROJECT_PATH=.
UNITY=/Applications/Unity/Hub/Editor/2018.2.5f1/Unity.app/Contents/MacOS/Unity'
}

unity::execute_method() {
  log_func "$@"
  "${UNITY}" \
  -projectPath "${UNITY_PROJECT_PATH}" \
  -batchmode \
  -executeMethod "$@" \
  -nographics \
  -logfile \
  -quit
}
