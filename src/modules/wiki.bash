# bee::help
# wiki : open wiki
# bee::help

: "${BEE_WIKI:=https://github.com/sschmid/bee/wiki}"

bee::wiki() {
  os_open "${BEE_WIKI}"
}
