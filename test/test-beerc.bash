# shellcheck disable=SC2034
BEE_ORIGIN="file://${BATS_TEST_TMPDIR}/testbee"
BEE_LATEST_VERSION_PATH="file://${BATS_TEST_DIRNAME}/testversion.txt"
BEE_LATEST_VERSION_CACHE_EXPIRE=0
BEE_MODULES_PATH="${BATS_TEST_DIRNAME}/fixtures/modules"
BEE_CACHES_PATH="${BATS_TEST_TMPDIR}/caches"
if [[ -v TEST_NO_PLUGINS ]]; then
  BEE_PLUGINS_PATHS=(unknown)
elif [[ -v TEST_CUSTOM_PLUGINS ]]; then
  BEE_PLUGINS_PATHS=(
    "${BATS_TEST_DIRNAME}/fixtures/plugins"
    "${BATS_TEST_DIRNAME}/fixtures/custom_plugins"
  )
else
  BEE_PLUGINS_PATHS=("${BATS_TEST_DIRNAME}/fixtures/plugins")
fi
