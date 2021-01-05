#!/usr/bin/env bash
#
# Author: @sschmid
# Execute methods in Unity

unity::_new() {
  echo "# unity"
  echo 'UNITY_PROJECT_PATH=.
UNITY=/Applications/Unity/Hub/Editor/2018.2.5f1/Unity.app/Contents/MacOS/Unity
UNITY_USER="user"
UNITY_PASSWORD="password"
UNITY_SERIAL="AB-1234-5678-1234-5678"'
}

unity::ping_project() {
  bee::log_func "$@"
  run_batchmode "$@"
}

unity::execute_method() {
  bee::log_func "$@"
  run_batchmode -executeMethod "$@"
}

unity::sync_solution() {
  unity::execute_method UnityEditor.SyncVS.SyncSolution "$@"
}

run_batchmode() {
  "${UNITY}" \
  -projectPath "${UNITY_PROJECT_PATH}" \
  -batchmode \
  -nographics \
  -logfile \
  -serial "${UNITY_SERIAL}" -username "$UNITY_USER" -password "${UNITY_PASSWORD}" \
  -quit "$@"
}
