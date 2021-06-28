# bee::help update | update bee to the latest version
bee::update() {
  if (($# == 0)); then
    pushd "${BEE_SYSTEM_HOME}" > /dev/null || exit 1
      git pull origin main
      bee::log "bee is up-to-date and ready to bzzzz"
    popd > /dev/null || exit 1
  else
    bee::usage
  fi
}
