setup() {
  load "test-helper.bash"
  load "test-helper-hub.bash"
  mkdir -p "${BATS_TEST_TMPDIR}/testplugin/2.0.0"
  _set_beerc
  _source_beerc
  _setup_test_bee_hub_repo
  _setup_testplugin_repo
}

assert_lint_error() {
  assert_version_lint_error 2.0.0 "$@"
}

assert_version_lint_error() {
  local version="$1"
  shift
  _lint "${version}"
  assert_failure
  assert_output "$@"
}

assert_lint_success() {
  _lint 2.0.0
  assert_success
  assert_output "$@"
}

_setup_test_bee_hub_repo_version() {
  rm -rf "${BATS_TEST_TMPDIR}/plugins"
  local version="$1"
  _setup_generic_plugin_repo testplugin "${version}"
  _update_generic_plugin_repo testplugin
}

_lint() {
  run bee lint "${BATS_TEST_TMPDIR}/testplugin/$1/plugin.json"
}

@test "lints missing name" {
  cat << EOF > "${BATS_TEST_TMPDIR}/testplugin/2.0.0/plugin.json"
{
  "version": "2.0.0",
  "license": "MIT",
  "homepage": "https://github.com/sschmid/bee",
  "authors": ["sschmid"],
  "info": "bee testplugin",
  "git": "file://${BATS_TEST_TMPDIR}/plugins/testplugin",
  "tag": "v2.0.0",
  "sha256": "27148c77a775131d6b480bc0987147b295c386dbd18434de30c66b96f949823c"
}
EOF

  assert_lint_error --regexp 'name.*testplugin'
}

@test "lints missing version" {
  cat << EOF > "${BATS_TEST_TMPDIR}/testplugin/2.0.0/plugin.json"
{
  "name": "testplugin",
  "license": "MIT",
  "homepage": "https://github.com/sschmid/bee",
  "authors": ["sschmid"],
  "info": "bee testplugin",
  "git": "file://${BATS_TEST_TMPDIR}/plugins/testplugin",
  "tag": "v2.0.0",
  "sha256": "27148c77a775131d6b480bc0987147b295c386dbd18434de30c66b96f949823c"
}
EOF

  assert_lint_error --regexp 'version.*2.0.0'
}

@test "lints missing license" {
  cat << EOF > "${BATS_TEST_TMPDIR}/testplugin/2.0.0/plugin.json"
{
  "name": "testplugin",
  "version": "2.0.0",
  "homepage": "https://github.com/sschmid/bee",
  "authors": ["sschmid"],
  "info": "bee testplugin",
  "git": "file://${BATS_TEST_TMPDIR}/plugins/testplugin",
  "tag": "v2.0.0",
  "sha256": "27148c77a775131d6b480bc0987147b295c386dbd18434de30c66b96f949823c"
}
EOF

  assert_lint_error --regexp 'license.*null'
}

@test "lints missing homepage" {
  cat << EOF > "${BATS_TEST_TMPDIR}/testplugin/2.0.0/plugin.json"
{
  "name": "testplugin",
  "version": "2.0.0",
  "license": "MIT",
  "authors": ["sschmid"],
  "info": "bee testplugin",
  "git": "file://${BATS_TEST_TMPDIR}/plugins/testplugin",
  "tag": "v2.0.0",
  "sha256": "27148c77a775131d6b480bc0987147b295c386dbd18434de30c66b96f949823c"
}
EOF

  assert_lint_error --regexp 'homepage.*null'
}

@test "lints missing authors" {
  cat << EOF > "${BATS_TEST_TMPDIR}/testplugin/2.0.0/plugin.json"
{
  "name": "testplugin",
  "version": "2.0.0",
  "license": "MIT",
  "homepage": "https://github.com/sschmid/bee",
  "info": "bee testplugin",
  "git": "file://${BATS_TEST_TMPDIR}/plugins/testplugin",
  "tag": "v2.0.0",
  "sha256": "27148c77a775131d6b480bc0987147b295c386dbd18434de30c66b96f949823c"
}
EOF

  assert_lint_error --regexp 'authors.*null'
}

@test "lints missing info" {
  cat << EOF > "${BATS_TEST_TMPDIR}/testplugin/2.0.0/plugin.json"
{
  "name": "testplugin",
  "version": "2.0.0",
  "license": "MIT",
  "homepage": "https://github.com/sschmid/bee",
  "authors": ["sschmid"],
  "git": "file://${BATS_TEST_TMPDIR}/plugins/testplugin",
  "tag": "v2.0.0",
  "sha256": "27148c77a775131d6b480bc0987147b295c386dbd18434de30c66b96f949823c"
}
EOF

  assert_lint_error --regexp 'info.*null'
}

@test "lints missing git" {
  cat << EOF > "${BATS_TEST_TMPDIR}/testplugin/2.0.0/plugin.json"
{
  "name": "testplugin",
  "version": "2.0.0",
  "license": "MIT",
  "homepage": "https://github.com/sschmid/bee",
  "authors": ["sschmid"],
  "info": "bee testplugin",
  "tag": "v2.0.0",
  "sha256": "27148c77a775131d6b480bc0987147b295c386dbd18434de30c66b96f949823c"
}
EOF

  assert_lint_error --regexp 'git.*null'
}

@test "lints missing tag" {
  cat << EOF > "${BATS_TEST_TMPDIR}/testplugin/2.0.0/plugin.json"
{
  "name": "testplugin",
  "version": "2.0.0",
  "license": "MIT",
  "homepage": "https://github.com/sschmid/bee",
  "authors": ["sschmid"],
  "info": "bee testplugin",
  "git": "file://${BATS_TEST_TMPDIR}/plugins/testplugin",
  "sha256": "27148c77a775131d6b480bc0987147b295c386dbd18434de30c66b96f949823c"
}
EOF

  assert_lint_error --regexp 'tag.*null'
}

@test "lints missing sha256" {
  cat << EOF > "${BATS_TEST_TMPDIR}/testplugin/2.0.0/plugin.json"
{
  "name": "testplugin",
  "version": "2.0.0",
  "license": "MIT",
  "homepage": "https://github.com/sschmid/bee",
  "authors": ["sschmid"],
  "info": "bee testplugin",
  "git": "file://${BATS_TEST_TMPDIR}/plugins/testplugin",
  "tag": "v2.0.0"
}
EOF

  assert_lint_error --regexp 'sha256.*null'
}

@test "lints missing dependencies" {
  cat << EOF > "${BATS_TEST_TMPDIR}/testplugin/2.0.0/plugin.json"
{
  "name": "testplugin",
  "version": "2.0.0",
  "license": "MIT",
  "homepage": "https://github.com/sschmid/bee",
  "authors": ["sschmid"],
  "info": "bee testplugin",
  "git": "file://${BATS_TEST_TMPDIR}/plugins/testplugin",
  "tag": "v2.0.0",
  "sha256": "27148c77a775131d6b480bc0987147b295c386dbd18434de30c66b96f949823c"
}
EOF

  assert_lint_success --regexp 'dependencies.*null'
}

@test "lints name is not plugin folder name" {
  cat << EOF > "${BATS_TEST_TMPDIR}/testplugin/2.0.0/plugin.json"
{
  "name": "xxx",
  "version": "2.0.0",
  "license": "MIT",
  "homepage": "https://github.com/sschmid/bee",
  "authors": ["sschmid"],
  "info": "bee testplugin",
  "git": "file://${BATS_TEST_TMPDIR}/plugins/testplugin",
  "tag": "v2.0.0",
  "sha256": "27148c77a775131d6b480bc0987147b295c386dbd18434de30c66b96f949823c"
}
EOF

  assert_lint_error --regexp 'name.*xxx.*testplugin'
}

@test "lints version is parent folder name" {
  cat << EOF > "${BATS_TEST_TMPDIR}/testplugin/2.0.0/plugin.json"
{
  "name": "testplugin",
  "version": "x.x.x",
  "license": "MIT",
  "homepage": "https://github.com/sschmid/bee",
  "authors": ["sschmid"],
  "info": "bee testplugin",
  "git": "file://${BATS_TEST_TMPDIR}/plugins/testplugin",
  "tag": "v2.0.0",
  "sha256": "27148c77a775131d6b480bc0987147b295c386dbd18434de30c66b96f949823c"
}
EOF

  assert_lint_error --regexp 'version.*x.x.x.*2.0.0'
}

@test "lints missing version file" {
  local version="1.0.0"
  mkdir -p "${BATS_TEST_TMPDIR}/testplugin/${version}"
  cat << EOF > "${BATS_TEST_TMPDIR}/testplugin/${version}/plugin.json"
{
  "name": "testplugin",
  "version": "${version}",
  "license": "MIT",
  "homepage": "https://github.com/sschmid/bee",
  "authors": ["sschmid"],
  "info": "bee testplugin",
  "git": "file://${BATS_TEST_TMPDIR}/plugins/testplugin",
  "tag": "v${version}",
  "sha256": "bef36a8260e6784bf8fb4ca93ff8ce5f6c07f0e7a326f1cbf41e1f64c1aa3d4d"
}
EOF

  assert_version_lint_error "${version}" --regexp 'version file.*null'
}

@test "lints incorrect version file" {
  local version="1.1.0"
  mkdir -p "${BATS_TEST_TMPDIR}/testplugin/${version}"
  cat << EOF > "${BATS_TEST_TMPDIR}/testplugin/${version}/plugin.json"
{
  "name": "testplugin",
  "version": "${version}",
  "license": "MIT",
  "homepage": "https://github.com/sschmid/bee",
  "authors": ["sschmid"],
  "info": "bee testplugin",
  "git": "file://${BATS_TEST_TMPDIR}/plugins/testplugin",
  "tag": "v${version}",
  "sha256": "6a84ce7a4869e415eea117e4e55baedebc34d6d32a4fa48fe8a3c573d3cc870d"
}
EOF

  _setup_test_bee_hub_repo_version "${version}"
  assert_version_lint_error "${version}" --regexp 'version.*x.x.x.*1.1.0'
}

@test "lints missing license file" {
  local version="1.2.0"
  mkdir -p "${BATS_TEST_TMPDIR}/testplugin/${version}"
  cat << EOF > "${BATS_TEST_TMPDIR}/testplugin/${version}/plugin.json"
{
  "name": "testplugin",
  "version": "${version}",
  "license": "MIT",
  "homepage": "https://github.com/sschmid/bee",
  "authors": ["sschmid"],
  "info": "bee testplugin",
  "git": "file://${BATS_TEST_TMPDIR}/plugins/testplugin",
  "tag": "v${version}",
  "sha256": "bebcdf4c3e7483cdf243c6ee0a0416e8f5e169f4895ba98b7d54eb2aaf40ee45"
}
EOF

  _setup_test_bee_hub_repo_version "${version}"
  assert_version_lint_error "${version}" --regexp 'license file.*null.*required'
}

@test "lints incorrect git" {
  cat << EOF > "${BATS_TEST_TMPDIR}/testplugin/2.0.0/plugin.json"
{
  "name": "testplugin",
  "version": "2.0.0",
  "license": "MIT",
  "homepage": "https://github.com/sschmid/bee",
  "authors": ["sschmid"],
  "info": "bee testplugin",
  "git": "file://${BATS_TEST_TMPDIR}/plugins/unknown",
  "tag": "v2.0.0",
  "sha256": "27148c77a775131d6b480bc0987147b295c386dbd18434de30c66b96f949823c"
}
EOF

  assert_lint_error --partial "##Egit clone ${BEE_CHECK_FAIL}#"
}

@test "lints incorrect tag" {
  cat << EOF > "${BATS_TEST_TMPDIR}/testplugin/2.0.0/plugin.json"
{
  "name": "testplugin",
  "version": "2.0.0",
  "license": "MIT",
  "homepage": "https://github.com/sschmid/bee",
  "authors": ["sschmid"],
  "info": "bee testplugin",
  "git": "file://${BATS_TEST_TMPDIR}/plugins/testplugin",
  "tag": "vx.x.x",
  "sha256": "27148c77a775131d6b480bc0987147b295c386dbd18434de30c66b96f949823c"
}
EOF

  assert_lint_error --partial "##Egit checkout tag ${BEE_CHECK_FAIL}#"
}

@test "lints incorrect sha256" {
  cat << EOF > "${BATS_TEST_TMPDIR}/testplugin/2.0.0/plugin.json"
{
  "name": "testplugin",
  "version": "2.0.0",
  "license": "MIT",
  "homepage": "https://github.com/sschmid/bee",
  "authors": ["sschmid"],
  "info": "bee testplugin",
  "git": "file://${BATS_TEST_TMPDIR}/plugins/testplugin",
  "tag": "v2.0.0",
  "sha256": "xxx"
}
EOF

  assert_lint_error --regexp 'sha256.*xxx.*27148c77a775131d6b480bc0987147b295c386dbd18434de30c66b96f949823c'
}

@test "lints missing plugin bash file" {
  local version="1.3.0"
  mkdir -p "${BATS_TEST_TMPDIR}/testplugin/${version}"
  cat << EOF > "${BATS_TEST_TMPDIR}/testplugin/${version}/plugin.json"
{
  "name": "testplugin",
  "version": "${version}",
  "license": "MIT",
  "homepage": "https://github.com/sschmid/bee",
  "authors": ["sschmid"],
  "info": "bee testplugin",
  "git": "file://${BATS_TEST_TMPDIR}/plugins/testplugin",
  "tag": "v${version}",
  "sha256": "283ae38b0e63b1aaf43ad76b6311da4cc7502c017dbc4f560de09d713c282925"
}
EOF

  _setup_test_bee_hub_repo_version "${version}"
  assert_version_lint_error "${version}" --regexp 'plugin file.*null.*required'
}

@test "lints incorrect dependencies" {
  local version="1.4.0"
  mkdir -p "${BATS_TEST_TMPDIR}/testplugin/${version}"
  cat << EOF > "${BATS_TEST_TMPDIR}/testplugin/${version}/plugin.json"
{
  "name": "testplugin",
  "version": "1.4.0",
  "license": "MIT",
  "homepage": "https://github.com/sschmid/bee",
  "authors": ["sschmid"],
  "info": "bee testplugin",
  "git": "file://${BATS_TEST_TMPDIR}/plugins/testplugin",
  "tag": "v1.4.0",
  "sha256": "bf5f633dad2196c0df9a0e4dad55fd59331a40cf7ba2cfc78e2dd4168af7d46d",
  "dependencies": ["testdep:1.0.0", "othertestdep:2.0.0"]
}
EOF

  _setup_test_bee_hub_repo_version "${version}"
  assert_version_lint_error "${version}" --regexp 'dependencies.*testdep:1.2.3 othertestdep:1.2.3'
}

@test "lints successfully" {
  cat << EOF > "${BATS_TEST_TMPDIR}/testplugin/2.0.0/plugin.json"
{
  "name": "testplugin",
  "version": "2.0.0",
  "license": "MIT",
  "homepage": "https://github.com/sschmid/bee",
  "authors": ["sschmid"],
  "info": "bee testplugin",
  "git": "file://${BATS_TEST_TMPDIR}/plugins/testplugin",
  "tag": "v2.0.0",
  "sha256": "27148c77a775131d6b480bc0987147b295c386dbd18434de30c66b96f949823c"
}
EOF

  assert_lint_success
}
