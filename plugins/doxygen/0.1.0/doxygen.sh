#!/usr/bin/env bash
#
# Author: @sschmid
# Generate docs with doxygen

DOXYGEN_BUILD=Build/docs

doxygen::_new() {
  echo "# doxygen => $(doxygen::_deps)"
  echo 'DOXYGEN_EXPORT_PATH=docs
DOXYGEN_DOXY_FILES=("${BEE_RESOURCES}"/docs/html.doxyfile)
DOXYGEN_DOCSET_NAME="${BEE_PROJECT}.docset"
DOXYGEN_DOCSET="com.company.${BEE_PROJECT}.docset"
DOXYGEN_DOCSET_KEY="$(echo "${BEE_PROJECT}" | tr "[:upper:]" "[:lower:]")"
DOXYGEN_DOCSET_ICONS=("${BEE_RESOURCES}"/docs/icon.png "${BEE_RESOURCES}"/docs/icon@2x.png)'
}

doxygen::_deps() {
  echo "utils version"
}

doxygen::generate_doxyfile() {
  log_func "${1}"
  sed -i .bak -e "s/PROJECT_NUMBER.*/PROJECT_NUMBER         = ${2}/" "${1}"
  rm "${1}.bak"
  doxygen "${1}"
}

doxygen::make_docset() {
  pushd "${DOXYGEN_BUILD}/docset" > /dev/null
    make
    # In order for Dash to associate this docset with the project keyword,
    # we have to manually modify the generated plist.
    # http://stackoverflow.com/questions/14678025/how-do-i-specify-a-keyword-for-dash-with-doxygen
    sed -i .bak -e "s/<\/dict>/<key>DocSetPlatformFamily<\/key><string>${DOXYGEN_DOCSET_KEY}<\/string><key>DashDocSetFamily<\/key><string>doxy<\/string><\/dict>/" "${DOXYGEN_DOCSET}/Contents/Info.plist"
    rm "${DOXYGEN_DOCSET}/Contents/Info.plist.bak"

    for f in "${DOXYGEN_DOCSET_ICONS[@]}"; do
      cp "${f}" "${DOXYGEN_DOCSET}"
    done

    mv "${DOXYGEN_DOCSET}" "${DOXYGEN_DOCSET_NAME}"
  popd > /dev/null
}

doxygen::generate() {
  log_func
  require doxygen
  utils::clean_dir "${DOXYGEN_BUILD}"

  local version="$(version::read)"
  for f in "${DOXYGEN_DOXY_FILES[@]}"; do
    doxygen::generate_doxyfile "${f}" "${version}"
  done

  utils::clean_dir "${DOXYGEN_EXPORT_PATH}"
  rsync -air "${DOXYGEN_BUILD}/html/" "${DOXYGEN_EXPORT_PATH}"
}
