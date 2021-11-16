os_open() {
  open "$@"
}

os_sha256sum() {
  shasum -a 256 "$@"
}
