#!/usr/bin/env bash
#
# Author: @sschmid
# Archive and upload to TestFlight

ios::_new() {
  echo '# ios
IOS_WORKSPACE="Build/iOS/${PROJECT}/Unity-iPhone.xcworkspace"
IOS_SCHEME="Unity-iPhone"
IOS_ARCHIVE="Build/iOS/${PROJECT}/${PROJECT}.xcarchive"
IOS_EXPORT_PATH="Build/iOS/${PROJECT}/Export"
IOS_EXPORT_OPTIONS="${RESOURCES}"/ios/ExportOptions.plist
IOS_IPA="Build/iOS/${PROJECT}/Export/Unity-iPhone.ipa"
ALTOOL="/Applications/Xcode.app/Contents/Applications/Application Loader.app/Contents/Frameworks/ITunesSoftwareService.framework/Support/altool"
IOS_USER="user"
IOS_PASSWORD="password"'
}

ios::archive() {
  log_func
  xcodebuild \
  -workspace "${IOS_WORKSPACE}" \
  -scheme "${IOS_SCHEME}" \
  -archivePath "${IOS_ARCHIVE}" \
  -quiet \
  archive
}

ios::export() {
  log_func
  xcodebuild \
  -exportArchive \
  -archivePath "${IOS_ARCHIVE}" \
  -exportPath "${IOS_EXPORT_PATH}" \
  -exportOptionsPlist "${IOS_EXPORT_OPTIONS}" \
  -quiet
}

ios::upload() {
  log_func
  "${ALTOOL}" --upload-app -f "${IOS_IPA}" -u "${IOS_USER}" -p "${IOS_PASSWORD}"
}

ios::dist() {
  ios::archive
  ios::export
  ios::upload
}
