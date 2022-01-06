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
  local version="$1"
  run bee lint "${BATS_TEST_TMPDIR}/testplugin/${version}/plugin.json"
}

@test "shows help when no args" {
  run bee lint
  assert_bee_help
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
  "sha256": "571d9351cab430b6fad540421de7ebcecd77946a55d1673e71034e0fa7dd51f4"
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
  "sha256": "571d9351cab430b6fad540421de7ebcecd77946a55d1673e71034e0fa7dd51f4"
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
  "sha256": "571d9351cab430b6fad540421de7ebcecd77946a55d1673e71034e0fa7dd51f4"
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
  "sha256": "571d9351cab430b6fad540421de7ebcecd77946a55d1673e71034e0fa7dd51f4"
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
  "sha256": "571d9351cab430b6fad540421de7ebcecd77946a55d1673e71034e0fa7dd51f4"
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
  "sha256": "571d9351cab430b6fad540421de7ebcecd77946a55d1673e71034e0fa7dd51f4"
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
  "sha256": "571d9351cab430b6fad540421de7ebcecd77946a55d1673e71034e0fa7dd51f4"
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
  "sha256": "571d9351cab430b6fad540421de7ebcecd77946a55d1673e71034e0fa7dd51f4"
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
  "sha256": "571d9351cab430b6fad540421de7ebcecd77946a55d1673e71034e0fa7dd51f4"
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
  "sha256": "571d9351cab430b6fad540421de7ebcecd77946a55d1673e71034e0fa7dd51f4"
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
  "sha256": "571d9351cab430b6fad540421de7ebcecd77946a55d1673e71034e0fa7dd51f4"
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
  "sha256": "03e057364297de0fda079ca9f91bb751ef22beecebf048c542c7b406fe391cd9"
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
  "sha256": "25f1125216f5c7bb6f2e96111f0de598bd67c5e19da50a1fc19538a7fdc9bbc4"
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
  "sha256": "571d9351cab430b6fad540421de7ebcecd77946a55d1673e71034e0fa7dd51f4"
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
  "sha256": "571d9351cab430b6fad540421de7ebcecd77946a55d1673e71034e0fa7dd51f4"
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

  assert_lint_error --regexp 'sha256.*xxx.*571d9351cab430b6fad540421de7ebcecd77946a55d1673e71034e0fa7dd51f4'
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
  "sha256": "eb5d35d19f4fe5828ec05e6ea31f2ae50e782683ff25c2efa72e80432d0ea6a7"
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
  "sha256": "b3bdc39713079809f38bf239f8a6c4e5a8c712b0c6ee4a7c11632d2228c78758",
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
  "sha256": "571d9351cab430b6fad540421de7ebcecd77946a55d1673e71034e0fa7dd51f4"
}
EOF

  assert_lint_success
}
