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
  "sha256": "25f806f487714bdce1717b2042673653f17e951c6d710561e09a9e1051005327"
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
  "sha256": "25f806f487714bdce1717b2042673653f17e951c6d710561e09a9e1051005327"
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
  "sha256": "25f806f487714bdce1717b2042673653f17e951c6d710561e09a9e1051005327"
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
  "sha256": "25f806f487714bdce1717b2042673653f17e951c6d710561e09a9e1051005327"
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
  "sha256": "25f806f487714bdce1717b2042673653f17e951c6d710561e09a9e1051005327"
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
  "sha256": "25f806f487714bdce1717b2042673653f17e951c6d710561e09a9e1051005327"
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
  "sha256": "25f806f487714bdce1717b2042673653f17e951c6d710561e09a9e1051005327"
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
  "sha256": "25f806f487714bdce1717b2042673653f17e951c6d710561e09a9e1051005327"
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
  "sha256": "25f806f487714bdce1717b2042673653f17e951c6d710561e09a9e1051005327"
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
  "sha256": "25f806f487714bdce1717b2042673653f17e951c6d710561e09a9e1051005327"
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
  "sha256": "25f806f487714bdce1717b2042673653f17e951c6d710561e09a9e1051005327"
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
  "sha256": "1c5e5a79a93b5272c5a3b342426de8b0bc6a5474bd5fa75372eba4feb69e826e"
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
  "sha256": "e7e869e984fb70a260f9bfa97f427de93bc75daf25e9b393879625d624b61ef0"
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
  "sha256": "25f806f487714bdce1717b2042673653f17e951c6d710561e09a9e1051005327"
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
  "sha256": "25f806f487714bdce1717b2042673653f17e951c6d710561e09a9e1051005327"
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

  assert_lint_error --regexp 'sha256.*xxx.*25f806f487714bdce1717b2042673653f17e951c6d710561e09a9e1051005327'
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
  "sha256": "71b5b50ae3ea86bdecc49f45c5ab9306f8568328819482d8ef882021cce4fab0",
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
  "sha256": "25f806f487714bdce1717b2042673653f17e951c6d710561e09a9e1051005327"
}
EOF

  assert_lint_success
}
