########################################
# Open the bee wiki in the default browser
########################################

if (( $# )); then
  bee::source "bee-help"
  exit 1
fi

os_open "${BEE_WIKI}"
