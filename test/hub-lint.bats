setup() {
  load "test-helper.bash"
  load "test-helper-hub.bash"
  mkdir -p "${BATS_TEST_TMPDIR}/testplugin/2.0.0"
  _set_beerc
}

_prepare_module() {
  _setup_test_bee_hub_repo
  _source_bee
}

_lint() {
  _setup_testplugin_repo
  run bee hub lint "${BATS_TEST_TMPDIR}/testplugin/2.0.0/plugin.json"
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
  "sha256": "876be9890323fde9d3cdff84e2c76c02a2c4147b18c77533b1ded4014388f163"
}
EOF

  _prepare_module
  _lint
  assert_failure
  assert_output --regexp 'name.*testplugin'
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
  "sha256": "876be9890323fde9d3cdff84e2c76c02a2c4147b18c77533b1ded4014388f163"
}
EOF

  _prepare_module
  _lint
  assert_failure
  assert_output --regexp 'version.*2.0.0'
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
  "sha256": "876be9890323fde9d3cdff84e2c76c02a2c4147b18c77533b1ded4014388f163"
}
EOF

  _prepare_module
  _lint
  assert_failure
  assert_output --regexp 'license.*null'
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
  "sha256": "876be9890323fde9d3cdff84e2c76c02a2c4147b18c77533b1ded4014388f163"
}
EOF

  _prepare_module
  _lint
  assert_failure
  assert_output --regexp 'homepage.*null'
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
  "sha256": "876be9890323fde9d3cdff84e2c76c02a2c4147b18c77533b1ded4014388f163"
}
EOF

  _prepare_module
  _lint
  assert_failure
  assert_output --regexp 'authors.*null'
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
  "sha256": "876be9890323fde9d3cdff84e2c76c02a2c4147b18c77533b1ded4014388f163"
}
EOF

  _prepare_module
  _lint
  assert_failure
  assert_output --regexp 'info.*null'
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
  "sha256": "876be9890323fde9d3cdff84e2c76c02a2c4147b18c77533b1ded4014388f163"
}
EOF

  _prepare_module
  _lint
  assert_failure
  assert_output --regexp 'git.*null'
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
  "sha256": "876be9890323fde9d3cdff84e2c76c02a2c4147b18c77533b1ded4014388f163"
}
EOF

  _prepare_module
  _lint
  assert_failure
  assert_output --regexp 'tag.*null'
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

  _prepare_module
  _lint
  assert_failure
  assert_output --regexp 'sha256.*null'
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
  "sha256": "876be9890323fde9d3cdff84e2c76c02a2c4147b18c77533b1ded4014388f163"
}
EOF

  _prepare_module
  _lint
  assert_success
  assert_output --regexp 'dependencies.*null'
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
  "sha256": "876be9890323fde9d3cdff84e2c76c02a2c4147b18c77533b1ded4014388f163"
}
EOF

  _prepare_module
  _lint
  assert_failure
  assert_output --regexp 'name.*testplugin'
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
  "sha256": "876be9890323fde9d3cdff84e2c76c02a2c4147b18c77533b1ded4014388f163"
}
EOF

  _prepare_module
  _lint
  assert_failure
  assert_output --regexp 'version.*2.0.0'
}

@test "lints missing version file" {
  mkdir -p "${BATS_TEST_TMPDIR}/testplugin/1.0.0"
  cat << EOF > "${BATS_TEST_TMPDIR}/testplugin/1.0.0/plugin.json"
{
  "name": "testplugin",
  "version": "1.0.0",
  "license": "MIT",
  "homepage": "https://github.com/sschmid/bee",
  "authors": ["sschmid"],
  "info": "bee testplugin",
  "git": "file://${BATS_TEST_TMPDIR}/plugins/testplugin",
  "tag": "v1.0.0",
  "sha256": "876be9890323fde9d3cdff84e2c76c02a2c4147b18c77533b1ded4014388f163"
}
EOF

  _prepare_module
  _setup_testplugin_repo
  run bee hub lint "${BATS_TEST_TMPDIR}/testplugin/1.0.0/plugin.json"
  assert_failure
  assert_output --regexp 'version file.*null'
}

@test "lints incorrect version file" {
  mkdir -p "${BATS_TEST_TMPDIR}/testplugin/1.1.0"
  cat << EOF > "${BATS_TEST_TMPDIR}/testplugin/1.1.0/plugin.json"
{
  "name": "testplugin",
  "version": "1.1.0",
  "license": "MIT",
  "homepage": "https://github.com/sschmid/bee",
  "authors": ["sschmid"],
  "info": "bee testplugin",
  "git": "file://${BATS_TEST_TMPDIR}/plugins/testplugin",
  "tag": "v1.1.0",
  "sha256": "876be9890323fde9d3cdff84e2c76c02a2c4147b18c77533b1ded4014388f163"
}
EOF

  _prepare_module
  _setup_generic_plugin_repo testplugin
  cp -r "${BATS_TEST_DIRNAME}/fixtures/plugins/testplugin/1.1.0/." "${BATS_TEST_TMPDIR}/plugins/testplugin"
  pushd "${BATS_TEST_TMPDIR}/plugins/testplugin" > /dev/null || exit 1
    git add . ; _git_commit -m "Release 1.1.0"; git tag "v1.1.0"
  popd > /dev/null || exit 1
  cp -r "${BATS_TEST_DIRNAME}/fixtures/plugins/testplugin/2.0.0/." "${BATS_TEST_TMPDIR}/plugins/testplugin"
  pushd "${BATS_TEST_TMPDIR}/plugins/testplugin" > /dev/null || exit 1
    git add . ; _git_commit -m "Release 2.0.0"; git tag "v2.0.0"
  popd > /dev/null || exit 1

  run bee hub lint "${BATS_TEST_TMPDIR}/testplugin/1.1.0/plugin.json"
  assert_failure
  assert_output --regexp 'version.*1.1.0'
}

@test "lints missing license file" {
  mkdir -p "${BATS_TEST_TMPDIR}/testplugin/1.0.0"
  cat << EOF > "${BATS_TEST_TMPDIR}/testplugin/1.0.0/plugin.json"
{
  "name": "testplugin",
  "version": "1.0.0",
  "license": "MIT",
  "homepage": "https://github.com/sschmid/bee",
  "authors": ["sschmid"],
  "info": "bee testplugin",
  "git": "file://${BATS_TEST_TMPDIR}/plugins/testplugin",
  "tag": "v1.0.0",
  "sha256": "876be9890323fde9d3cdff84e2c76c02a2c4147b18c77533b1ded4014388f163"
}
EOF

  _prepare_module
  _setup_testplugin_repo
  run bee hub lint "${BATS_TEST_TMPDIR}/testplugin/1.0.0/plugin.json"
  assert_failure
  assert_output --regexp 'license file.*null'
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
  "sha256": "876be9890323fde9d3cdff84e2c76c02a2c4147b18c77533b1ded4014388f163"
}
EOF

  _prepare_module
  _lint
  assert_failure
  assert_output --partial "git clone ✗"
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
  "sha256": "876be9890323fde9d3cdff84e2c76c02a2c4147b18c77533b1ded4014388f163"
}
EOF

  _prepare_module
  _lint
  assert_failure
  assert_output --partial "git checkout tag ✗"
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

  _prepare_module
  _lint
  assert_failure
  assert_output --regexp 'sha256.*xxx'
  assert_output --partial "876be9890323fde9d3cdff84e2c76c02a2c4147b18c77533b1ded4014388f163"
}

@test "lints missing plugin bash file" {
  mkdir -p "${BATS_TEST_TMPDIR}/testplugin/1.3.0"
  cat << EOF > "${BATS_TEST_TMPDIR}/testplugin/1.3.0/plugin.json"
{
  "name": "testplugin",
  "version": "1.3.0",
  "license": "MIT",
  "homepage": "https://github.com/sschmid/bee",
  "authors": ["sschmid"],
  "info": "bee testplugin",
  "git": "file://${BATS_TEST_TMPDIR}/plugins/testplugin",
  "tag": "v1.3.0",
  "sha256": "318fe386882c12965ebfeb6648c5b3189386279cb17e2b86295c55f99950752d"
}
EOF

  _prepare_module
  _setup_generic_plugin_repo testplugin
  cp -r "${BATS_TEST_DIRNAME}/fixtures/plugins/testplugin/1.3.0/." "${BATS_TEST_TMPDIR}/plugins/testplugin"
  rm "${BATS_TEST_TMPDIR}/plugins/testplugin/testplugin.bash"
  pushd "${BATS_TEST_TMPDIR}/plugins/testplugin" > /dev/null || exit 1
    git add . ; _git_commit -m "Release 1.3.0"; git tag "v1.3.0"
  popd > /dev/null || exit 1
  cp -r "${BATS_TEST_DIRNAME}/fixtures/plugins/testplugin/2.0.0/." "${BATS_TEST_TMPDIR}/plugins/testplugin"
  rm "${BATS_TEST_TMPDIR}/plugins/testplugin/testplugin.bash"
  pushd "${BATS_TEST_TMPDIR}/plugins/testplugin" > /dev/null || exit 1
    git add . ; _git_commit -m "Release 2.0.0"; git tag "v2.0.0"
  popd > /dev/null || exit 1

  run bee hub lint "${BATS_TEST_TMPDIR}/testplugin/1.3.0/plugin.json"
  assert_failure
  assert_output --regexp 'plugin file.*null'
}

@test "lints incorrect dependencies" {
  mkdir -p "${BATS_TEST_TMPDIR}/testplugin/1.4.0"
  cat << EOF > "${BATS_TEST_TMPDIR}/testplugin/1.4.0/plugin.json"
{
  "name": "testplugin",
  "version": "1.4.0",
  "license": "MIT",
  "homepage": "https://github.com/sschmid/bee",
  "authors": ["sschmid"],
  "info": "bee testplugin",
  "git": "file://${BATS_TEST_TMPDIR}/plugins/testplugin",
  "tag": "v1.4.0",
  "sha256": "a7c32081d622f68fb6e4eaee97cd7f299509035a75f02a848f9e019993415618",
  "dependencies": ["testdep:1.0.0", "othertestdep:2.0.0"]
}
EOF

  _prepare_module
  _setup_generic_plugin_repo testplugin
  cp -r "${BATS_TEST_DIRNAME}/fixtures/plugins/testplugin/1.4.0/." "${BATS_TEST_TMPDIR}/plugins/testplugin"
  pushd "${BATS_TEST_TMPDIR}/plugins/testplugin" > /dev/null || exit 1
    git add . ; _git_commit -m "Release 1.4.0"; git tag "v1.4.0"
  popd > /dev/null || exit 1
  cp -r "${BATS_TEST_DIRNAME}/fixtures/plugins/testplugin/2.0.0/." "${BATS_TEST_TMPDIR}/plugins/testplugin"
  pushd "${BATS_TEST_TMPDIR}/plugins/testplugin" > /dev/null || exit 1
    git add . ; _git_commit -m "Release 2.0.0"; git tag "v2.0.0"
  popd > /dev/null || exit 1

  run bee hub lint "${BATS_TEST_TMPDIR}/testplugin/1.4.0/plugin.json"
  assert_failure
  assert_output --regexp 'dependencies.*must'
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
  "sha256": "876be9890323fde9d3cdff84e2c76c02a2c4147b18c77533b1ded4014388f163"
}
EOF

  _prepare_module
  _lint
  assert_success
}
