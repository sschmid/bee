# shellcheck disable=SC2034
BEE_ORIGIN="file://${BATS_TEST_TMPDIR}/testbee"
BEE_LATEST_VERSION_PATH="file://${PROJECT_ROOT}/test/testversion.txt"
BEE_LATEST_VERSION_CACHE_EXPIRE=0
BEE_MODULES_PATH="${PROJECT_ROOT}/test/fixtures/modules"
BEE_CACHES_PATH="${BATS_TEST_TMPDIR}/caches"
if [[ -v TEST_NO_PLUGINS ]]; then
  BEE_PLUGINS_PATHS=(unknown)
elif [[ -v TEST_CUSTOM_PLUGINS ]]; then
  BEE_PLUGINS_PATHS=(
    "${PROJECT_ROOT}/test/fixtures/plugins"
    "${PROJECT_ROOT}/test/fixtures/custom_plugins"
  )
else
  BEE_PLUGINS_PATHS=("${PROJECT_ROOT}/test/fixtures/plugins")
fi
