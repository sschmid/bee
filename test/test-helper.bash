_common_setup() {
  load 'test_helper/bats-support/load.bash'
  load 'test_helper/bats-assert/load.bash'
  load 'test_helper/bats-file/load.bash'

  bats_require_minimum_version 1.5.0

  export BATS_TEST_DIRNAME
  PROJECT_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." &>/dev/null && pwd)"
  PATH="${PROJECT_ROOT}/src:${PATH}"

  export BEE_COLOR_SUCCESS="#S"
  export BEE_COLOR_WARN="#W"
  export BEE_COLOR_FAIL="#E"
  export BEE_COLOR_RESET="#"
  export BEE_LINE_RESET="#"
  export BEE_CHECK_SUCCESS="BEE_CHECK_SUCCESS"
  export BEE_CHECK_FAIL="BEE_CHECK_FAIL"
  export BEE_RESULT="BEE_RESULT"
  export BEE_ICON="BEE_ICON"
  export BEE_WARNING="BEE_WARNING"
  export BEE_ERROR="BEE_ERROR"

  export BEE_OSTYPE="generic"

  export TEST_HUB_1="test_hub_1"
  export TEST_HUB_2="test_hub_2"

  # shellcheck disable=SC2034
  ALL_BEE_OPTIONS=(
    --batch
    --help
    --quiet
    --verbose
  )

  # shellcheck disable=SC2034
  ALL_BEE_COMMANDS=(
    cache
    env
    hash
    hubs
    info
    install
    job
    lint
    new
    plugins
    pull
    res
    update
    version
    wiki
  )

  # shellcheck disable=SC2034
  ALL_TEST_PLUGINS=(
    plugin_1
    plugin_2
    plugin_with_deps
    plugin_with_recursive_deps
    plugin_with_missing_deps
    plugin_with_wrong_hash
  )

  # shellcheck disable=SC2034
  ALL_CUSTOM_PLUGINS=(
    custom_plugin
    local_plugin
  )

  _create_beefile_with :
}

_export_beerc() {
  _export_beerc_with :
}

_export_beerc_with() {
  cp "${BATS_TEST_DIRNAME}/fixtures/beerc.bash" "${BATS_TEST_TMPDIR}/beerc.bash"
  export BEE_RC="${BATS_TEST_TMPDIR}/beerc.bash"
  for arg in "$@"; do
    echo "${arg}" >>"${BATS_TEST_TMPDIR}/beerc.bash"
  done
}

_export_beerc_fixture() {
  export BEE_RC="${BATS_TEST_DIRNAME}/fixtures/test-beerc.bash"
}

# shellcheck disable=SC1090
_source_beerc() {
  source "${BEE_RC}"
}

_create_beefile_with() {
  echo "$@" >"${BATS_TEST_TMPDIR}/Beefile"
  export BEE_FILE="${BATS_TEST_TMPDIR}/Beefile"
}

_unset_beefile() {
  unset BEE_FILE
  rm "${BATS_TEST_TMPDIR}/Beefile"
}

_git_commit() {
  git -c user.name=bee -c user.email=bee -c commit.gpgsign=false commit "$@"
}

assert_bee_help() {
  assert_output --partial "plugin-based bash automation"
}

# shellcheck disable=SC2207,SC2206,SC2068
assert_comp() {
  export COMP_LINE="$1"
  export COMP_POINT="${#COMP_LINE}"
  _disable_plugin_log
  run bee bee::comp
  actual=("${output}")
  actual=($(for i in ${actual[@]}; do echo "$i"; done | LC_ALL=C sort))
  if [[ -v 2 ]]; then
    expected=($2)
    expected=($(for i in ${expected[@]}; do echo "$i"; done | LC_ALL=C sort))
  fi

  if(( $# )); then
    assert_equal "${actual[*]}" "${expected[*]}"
  else
    refute_output
  fi
}

_plugin_log() {
  echo "$@"
}
export -f _plugin_log

_disable_plugin_log() {
  # shellcheck disable=SC2317
  _plugin_log() { :; }
}

################################################################################
# hubs
################################################################################
_create_bee_hub_repo() {
  local hub="$1"
  __prepare_hub_creation "${hub}"
    cp -r "${BATS_TEST_DIRNAME}/fixtures/hub/" .
    local file
    while IFS= read -r -d '' file; do
      sed -i '' -e "s;\$HOME;${BATS_TEST_TMPDIR};" -- "${file}"
    done < <(find . -type f -name "plugin.json" -print0)
  __finish_hub_creation "Initial commit"
}

_create_empty_bee_hub_repo() {
  local hub="$1"
  __prepare_hub_creation "${hub}"
    echo "empty" >empty.txt
  __finish_hub_creation "Initial commit"
}

_create_mock_bee_hub_repo() {
  local hub="$1" plugin="$2" version="${3:-"1.0.0"}" commit_message="${4:-"Initial commit"}"
  __prepare_hub_creation "${hub}"
    mkdir -p "${plugin}/${version}"
    touch "${plugin}/${version}/plugin.json"
  __finish_hub_creation "${commit_message}"
}

_update_mock_bee_hub_repo() {
  local hub="$1" plugin="$2" version="${3:-"2.0.0"}"
  local commit_message="${4:-"Release ${version}"}"
  _create_mock_bee_hub_repo "${hub}" "${plugin}" "${version}" "${commit_message}"
}

_create_generic_plugin_repo() {
  local plugin_name="$1" version="${2:-"1.0.0"}"
  mkdir -p "${BATS_TEST_TMPDIR}/plugins"
  cp -r "${BATS_TEST_DIRNAME}/fixtures/plugins/${plugin_name}/${version}/" "${BATS_TEST_TMPDIR}/plugins/${plugin_name}"
  pushd "${BATS_TEST_TMPDIR}/plugins/${plugin_name}" >/dev/null || exit 1
    git init
    git add .
    _git_commit -m "Initial commit"
    git tag "v${version}"
  popd >/dev/null || exit 1
}

_update_generic_plugin_repo() {
  local plugin_name="$1" version="${2:-"2.0.0"}"
  _create_generic_plugin_repo "${plugin_name}" "${version}"
}

_create_plugin_repo() {
  _create_generic_plugin_repo plugin_1
  _update_generic_plugin_repo plugin_1
}

__prepare_hub_creation() {
  local hub="$1"
  mkdir -p "${BATS_TEST_TMPDIR}/${hub}"
  pushd "${BATS_TEST_TMPDIR}/${hub}" >/dev/null || exit 1
}

__finish_hub_creation() {
  local commit_message="$1"
  git init
  git add .
  _git_commit -m "${commit_message}"
  popd >/dev/null || exit 1
}
