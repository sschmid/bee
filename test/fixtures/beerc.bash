# shellcheck disable=SC2034
BEE_ORIGIN="file://${BATS_TEST_TMPDIR}/testbee"
BEE_LATEST_VERSION_PATH="file://${BATS_TEST_DIRNAME}/fixtures/testversion.txt"
declare -ig BEE_LATEST_VERSION_CACHE_EXPIRE=3
declare -ig BEE_HUB_PULL_COOLDOWN=999
BEE_HUBS=(
  "file://${BATS_TEST_TMPDIR}/testhub"
  "file://${BATS_TEST_TMPDIR}/othertesthub"
)
BEE_CACHE_PATH="${BATS_TEST_TMPDIR}/cache"

if [[ -v TEST_BEE_PLUGINS_NEED_INSTALL ]]; then
  BEE_PLUGINS_PATHS=(
    "${BEE_CACHE_PATH}/plugins"
    "${BATS_TEST_DIRNAME}/fixtures/custom_plugins"
  )
elif [[ -v TEST_BEE_PLUGINS_PATHS_CUSTOM ]]; then
  BEE_PLUGINS_PATHS=(
    "${BATS_TEST_DIRNAME}/fixtures/plugins"
    "${BATS_TEST_DIRNAME}/fixtures/custom_plugins"
  )
else
  BEE_PLUGINS_PATHS=("${BATS_TEST_DIRNAME}/fixtures/plugins")
fi
