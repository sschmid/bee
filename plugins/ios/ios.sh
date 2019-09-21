#!/usr/bin/env bash
#
# Author: @sschmid
# Archive and upload to TestFlight

ios::_new() {
  echo "# ios"
  echo 'IOS_PROJECT="Build/iOS/${PROJECT}/Unity-iPhone.xcodeproj"
IOS_WORKSPACE="Build/iOS/${PROJECT}/Unity-iPhone.xcworkspace"
IOS_SCHEME="Unity-iPhone"
IOS_ARCHIVE="Build/iOS/${PROJECT}/${PROJECT}.xcarchive"
IOS_EXPORT_PATH="Build/iOS/${PROJECT}/Export"
IOS_EXPORT_OPTIONS="${RESOURCES}"/ios/ExportOptions.plist
IOS_IPA="Build/iOS/${PROJECT}/Export/Unity-iPhone.ipa"
IOS_USER="user"
IOS_PASSWORD="password"'
}

ios::archive_project() {
  log_func
  xcodebuild \
  -project "${IOS_PROJECT}" \
  -scheme "${IOS_SCHEME}" \
  -archivePath "${IOS_ARCHIVE}" \
  -quiet \
  archive
}

ios::archive_workspace() {
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
  xcrun altool --upload-app -f "${IOS_IPA}" -u "${IOS_USER}" -p "${IOS_PASSWORD}"
}
