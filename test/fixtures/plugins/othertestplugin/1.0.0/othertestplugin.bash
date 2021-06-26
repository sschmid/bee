if [[ -v OTHERTESTPLUGIN_SOURCED ]]; then
  echo "# ERROR: already sourced"
  exit 1
fi

OTHERTESTPLUGIN_SOURCED=1
echo "# othertestplugin 1.0.0 sourced"

othertestplugin() {
  if (($# > 0)); then
    # shellcheck disable=SC2145
    echo "hello from othertestplugin 1.0.0 - $@"
  else
    echo "hello from othertestplugin 1.0.0"
  fi
}

othertestplugin::help() {
  echo "othertestplugin 1.0.0 help"
}

othertestplugin::greet() {
  if (($# > 0)); then
    # shellcheck disable=SC2145
    echo "greeting $@ from othertestplugin 1.0.0"
  else
    echo "greeting from othertestplugin 1.0.0"
  fi
}
