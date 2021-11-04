# shellcheck disable=SC2034
BEE_ORIGIN="file://${BATS_TEST_TMPDIR}/testbee"
BEE_LATEST_VERSION_PATH="file://${BATS_TEST_DIRNAME}/fixtures/testversion.txt"
declare -ig BEE_LATEST_VERSION_CACHE_EXPIRE=0
declare -ig BEE_HUB_PULL_COOLDOWN=0
BEE_HUBS=(
  "file://${BATS_TEST_TMPDIR}/testhub"
  "file://${BATS_TEST_TMPDIR}/othertesthub"
)
BEE_CACHES_PATH="${BATS_TEST_TMPDIR}/caches"

if [[ -v TEST_BEE_PLUGINS_PATHS_UNKNOWN ]]; then
  BEE_PLUGINS_PATHS=(unknown)
elif [[ -v TEST_BEE_PLUGINS_PATHS_CUSTOM ]]; then
  BEE_PLUGINS_PATHS=(
    "${BATS_TEST_DIRNAME}/fixtures/plugins"
    "${BATS_TEST_DIRNAME}/fixtures/custom_plugins"
  )
else
  BEE_PLUGINS_PATHS=("${BATS_TEST_DIRNAME}/fixtures/plugins")
fi

if [[ -v TEST_BEE_MODULES_PATH ]]; then
  BEE_MODULES_PATH="${BATS_TEST_DIRNAME}/fixtures/modules"
fi
