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
  assert_lint_error_with_version 2.0.0 "$@"
}

assert_lint_error_with_version() {
  local version="$1"; shift
  _lint "${version}"
  assert_failure
  assert_output "$@"
}

assert_lint_error_without() {
  _spec
  sed -i -e "/\"$1\":/d" "${BATS_TEST_TMPDIR}/testplugin/2.0.0/plugin.json"
  assert_lint_error --regexp "$2"
}

assert_lint_error_replace() {
  _spec
  sed -i -e "s/\"$1\":.*/\"$1\": $2,/g" "${BATS_TEST_TMPDIR}/testplugin/2.0.0/plugin.json"
  assert_lint_error --regexp "$3"
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

_spec() {
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
  "sha256": "37b987c21cf91f12d61aa9b3e2dda4b921f6467e6c83acd6f0765f825a4e0bef",
  "unknown": "null"
}
EOF
}

_lint() {
  local version="$1"
  run bee lint "${BATS_TEST_TMPDIR}/testplugin/${version}/plugin.json"
}

@test "shows help when no args" {
  run bee lint
  assert_failure
  assert_bee_help
}

@test "lints missing name" {
  assert_lint_error_without "name" 'name.*testplugin'
}

@test "lints missing version" {
  assert_lint_error_without "version" 'version.*2.0.0'
}

@test "lints missing license" {
  assert_lint_error_without "license" 'license.*null'
}

@test "lints missing homepage" {
  assert_lint_error_without "homepage" 'homepage.*null'
}

@test "lints missing authors" {
  assert_lint_error_without "authors" 'authors.*null'
}

@test "lints missing info" {
  assert_lint_error_without "info" 'info.*null'
}

@test "lints missing git" {
  assert_lint_error_without "git" 'git.*null'
}

@test "lints missing tag" {
  assert_lint_error_without "tag" 'tag.*null'
}

@test "lints missing sha256" {
  assert_lint_error_without "sha256" 'sha256.*null'
}

@test "lints missing dependencies" {
  _spec
  assert_lint_success --regexp 'dependencies.*null'
}

@test "lints name is not plugin folder name" {
  assert_lint_error_replace "name" '"xxx"' 'name.*xxx.*testplugin'
}

@test "lints version is parent folder name" {
  assert_lint_error_replace "version" '"x.x.x"' 'version.*x.x.x.*2.0.0'
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

  assert_lint_error_with_version "${version}" --regexp 'version file.*null'
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
  "sha256": "1c5e5a79a93b5272c5a3b342426de8b0bc6a5474bd5fa75372eba4feb69e826e"
}
EOF

  _setup_test_bee_hub_repo_version "${version}"
  assert_lint_error_with_version "${version}" --regexp 'version.*x.x.x.*1.1.0'
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
  "sha256": "e7e869e984fb70a260f9bfa97f427de93bc75daf25e9b393879625d624b61ef0"
}
EOF

  _setup_test_bee_hub_repo_version "${version}"
  assert_lint_error_with_version "${version}" --regexp 'license file.*null.*required'
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
  "sha256": "5ebab3a1c8be86a86145ecb7edcfa567e4c0a24066953e321debd8ea23ffd472"
}
EOF

  assert_lint_error --partial "##Egit clone ${BEE_CHECK_FAIL}#"
}

@test "lints incorrect tag" {
  assert_lint_error_replace "tag" '"vx.x.x"' "##Egit checkout tag ${BEE_CHECK_FAIL}#"
}

@test "lints incorrect sha256" {
  assert_lint_error_replace "sha256" '"xxx"' 'sha256.*xxx.*37b987c21cf91f12d61aa9b3e2dda4b921f6467e6c83acd6f0765f825a4e0bef'
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
  "sha256": "3af4ae44b0069f8cac7ccbc41b0adacdfb74f5767eb7882d20379d57e9e94e24"
}
EOF

  _setup_test_bee_hub_repo_version "${version}"
  assert_lint_error_with_version "${version}" --regexp 'plugin file.*null.*required'
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
  "sha256": "71b5b50ae3ea86bdecc49f45c5ab9306f8568328819482d8ef882021cce4fab0",
  "dependencies": ["testdep:1.0.0", "othertestdep:2.0.0"]
}
EOF

  _setup_test_bee_hub_repo_version "${version}"
  assert_lint_error_with_version "${version}" --regexp 'dependencies.*testdep:1.2.3 othertestdep:1.2.3'
}

@test "lints successfully" {
  _spec
  assert_lint_success
}
