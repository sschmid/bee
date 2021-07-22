load '../test_helper/bats-support/load.bash'
load '../test_helper/bats-assert/load.bash'
load '../test_helper/bats-file/load.bash'

_strict() {
  set -euo pipefail
  IFS=$'\n\t'
  "$@"
}
