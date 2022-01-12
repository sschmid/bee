bee::deps() {
  echo "changelog"
  echo "github"
}

bee::release() {
  changelog::merge
  git add .
  local version
  version="$(semver::read)"
  git commit -m "Release ${version}"
  git push
  git tag "${version}"
  git push --tags
  github::create_release
}
