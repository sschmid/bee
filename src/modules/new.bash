# bee::help
# new : create new Beefile
# bee::help

bee::new() {
  local beefile="${1:-Beefile}"
  if [[ -f "${beefile}" ]]; then
    bee::log_error "${beefile} already exists"
    exit 1
  else
    cat << EOF > "${beefile}"
BEE_PROJECT=$(basename "${PWD}")
BEE_VERSION=$(cat "${BEE_HOME}/version.txt")
BEE_RESOURCES=.bee

# Which plugins would you like to load?
# Standard plugins can be found in the official bee plugin register: https://github.com/sschmid/beehub
# More registers (and private registers) can be added by customizing ~/.beerc
#   BEE_HUBS=(
#     https://github.com/sschmid/beehub.git
#     https://github.com/my/beehub.git
#   )
#
# Custom plugins may be added by customizing ~/.beerc
#   BEE_PLUGINS_PATHS=(
#     "${BEE_CACHES_PATH}/plugins"
#     "${HOME}/path/to/my/plugins"
#   )
#
# Example format: BEE_PLUGINS=(changelog github:2.0.0 slack:1.0.0 version)
# You can specify a plugin version like this: plugin:x.y.z,
# otherwise the latest plugin version will be used
BEE_PLUGINS=(
  # android
  # changelog
  # github
  # ios
  # macos
  # sample
  # slack
  # tree
  # unity
  # version
)
EOF
    bee::log_echo "Created ${beefile}"
  fi
}
