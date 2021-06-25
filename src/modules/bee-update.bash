bee::update() {
  if (($# == 0)); then
    pushd "${BEE_SYSTEM_HOME}" > /dev/null
      git pull -q origin main
      bee::log "bee is up-to-date and ready to bzzzz"
    popd > /dev/null
  else
    bee::usage
  fi
}
