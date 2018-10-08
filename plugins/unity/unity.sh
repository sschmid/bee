#!/usr/bin/env bash
#
# Author: @sschmid
# Execute methods in Unity

unity::_new() {
  echo '# unity
UNITY_PROJECT_PATH=.
UNITY=/Applications/Unity/Hub/Editor/2018.2.5f1/Unity.app/Contents/MacOS/Unity'
}

unity::execute_method() {
  log_func "$@"
  "${UNITY}" \
  -quit \
  -batchmode \
  -nographics \
  -projectPath "${UNITY_PROJECT_PATH}" \
  -executeMethod "$@"
}
