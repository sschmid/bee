#!/usr/bin/env bash
#
# Author: @sschmid
# Archive and upload to TestFlight

ios::_new() {
  echo "# ios"
  echo 'IOS_PROJECT="Build/iOS/${BEE_PROJECT}/Unity-iPhone.xcodeproj"
IOS_WORKSPACE="Build/iOS/${BEE_PROJECT}/Unity-iPhone.xcworkspace"
IOS_SCHEME="Unity-iPhone"
IOS_ARCHIVE="Build/iOS/${BEE_PROJECT}/${BEE_PROJECT}.xcarchive"
IOS_EXPORT_PATH="Build/iOS/${BEE_PROJECT}/Export"
IOS_EXPORT_OPTIONS="${BEE_RESOURCES}"/ios/ExportOptions.plist
IOS_IPA="Build/iOS/${BEE_PROJECT}/Export/Unity-iPhone.ipa"
IOS_USER="user"
IOS_PASSWORD="password"'
}

ios::archive_project() {
  bee::log_func
  xcodebuild \
  -project "${IOS_PROJECT}" \
  -scheme "${IOS_SCHEME}" \
  -archivePath "${IOS_ARCHIVE}" \
  -quiet \
  archive
}

ios::archive_workspace() {
  bee::log_func
  xcodebuild \
  -workspace "${IOS_WORKSPACE}" \
  -scheme "${IOS_SCHEME}" \
  -archivePath "${IOS_ARCHIVE}" \
  -quiet \
  archive
}

ios::export() {
  bee::log_func
  xcodebuild \
  -exportArchive \
  -archivePath "${IOS_ARCHIVE}" \
  -exportPath "${IOS_EXPORT_PATH}" \
  -exportOptionsPlist "${IOS_EXPORT_OPTIONS}" \
  -quiet
}

ios::upload() {
  bee::log_func
  xcrun altool --upload-app -f "${IOS_IPA}" -u "${IOS_USER}" -p "${IOS_PASSWORD}"
}
