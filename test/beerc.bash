# shellcheck disable=SC2034
BEE_ORIGIN="file://${BATS_TEST_TMPDIR}/testbee"
BEE_LATEST_VERSION_PATH="file://${PROJECT_ROOT}/test/testversion.txt"
BEE_LATEST_VERSION_CACHE_EXPIRE=0
BEE_CACHES_PATH="${BATS_TEST_TMPDIR}/caches"
BEE_PLUGINS_PATHS=("${PROJECT_ROOT}/test/fixtures/plugins")
