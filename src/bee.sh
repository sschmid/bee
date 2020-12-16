#!/usr/bin/env bash
#
# 🐝 bee - plugin-based bash automation
#
# Shell Style Guide
# https://google.github.io/styleguide/shell.xml
set -eu

resolve_bee_home() {
  local current_dir="${PWD}"
  local path="${1}"
  while [[ -L ${path} ]]; do
    local link="$(readlink "${path}")"
    cd "$(dirname "${path}")"
    cd "$(dirname "${link}")"
    path="${link}"
  done
  cd "${current_dir}"
  echo "$(dirname "$(dirname "${path}")")"
}

export BEE_SYSTEM_HOME="$(resolve_bee_home "${BASH_SOURCE[0]}")"
export BEE_HOME="${BEE_SYSTEM_HOME}"

if [[ ! -f "${HOME}/.beerc" ]]; then
  echo "#!/usr/bin/env bash" > "${HOME}/.beerc"
  echo 'export BEE_PLUGINS=("${BEE_SYSTEM_HOME}/plugins")' >> "${HOME}/.beerc"
fi
source "${HOME}/.beerc"

# migration support
source "${BEE_SYSTEM_HOME}/src/bee_migration_0370.sh"

if [[ ! -v BEE_RC ]]; then
  if [[ -f .beerc ]]; then
    export BEE_RC=.beerc
    source "${BEE_RC}"
  else
    export BEE_RC="${HOME}/.beerc"
  fi
else
  source "${BEE_RC}"
fi

if [[ -v BEE_VERSION ]]; then
  BEE_HOME="${HOME}/.bee/versions/${BEE_VERSION}"
  source "${BEE_RC}"
  if [[ ! -d "${BEE_HOME}" ]]; then
    git -c advice.detachedHead=false clone --depth 1 --branch "${BEE_VERSION}" git@github.com:sschmid/bee.git "${BEE_HOME}"
  fi
fi

source "${BEE_HOME}/src/bee_runner.sh"
bee_run "$@"
