#!/usr/bin/env bash
#
# 🐝 bee - plugin-based bash automation
#
# Shell Style Guide
# https://google.github.io/styleguide/shell.xml
#
# "bash strict mode"
# http://redsymbol.net/articles/unofficial-bash-strict-mode/

set -euo pipefail
IFS=$'\n\t'

resolve_home() {
  local current_dir="${PWD}"
  local path="${1}"
  while [[ -L ${path} ]]; do
    local link="$(readlink "${path}")"
    cd "$(dirname "${path}")"
    cd "$(dirname "${link}")"
    path="${link}"
  done
  cd "${current_dir}"
  dirname "$(dirname "${path}")"
}

BEE_SYSTEM_HOME="$(resolve_home "${BASH_SOURCE[0]}")"
BEE_RESOURCES=.bee

if [[ ! -f "${HOME}/.beerc" ]]; then
  {
    echo "#!/usr/bin/env bash"
    echo "BEE_PLUGINS=()"
  } > "${HOME}/.beerc"
fi
source "${HOME}/.beerc"

# TODO: remove when expired
source "${BEE_SYSTEM_HOME}/src/bee_migration_0370.sh"

if [[ -v BEE_RC ]]; then
  source "${BEE_RC}"
else
  if [[ -f .beerc ]]; then
    BEE_RC=.beerc
    source "${BEE_RC}"
  fi
fi

if [[ -v BEE_VERSION ]]; then
  BEE_HOME="${HOME}/.bee/versions/${BEE_VERSION}"
  if [[ ! -d "${BEE_HOME}" ]]; then
    git -c advice.detachedHead=false clone --depth 1 --branch "${BEE_VERSION}" git@github.com:sschmid/bee.git "${BEE_HOME}"
  fi
else
  BEE_HOME="${BEE_SYSTEM_HOME}"
fi

BEE_PLUGINS+=("${BEE_HOME}/plugins")
source "${BEE_HOME}/src/bee_runner.sh"
bee_run "$@"
