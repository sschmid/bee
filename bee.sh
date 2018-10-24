#!/usr/bin/env bash
PROJECT="bee"
PLUGINS=(changelog git github version)
RESOURCES=.bee

source "${RESOURCES}"/bee.sh

# changelog => version
CHANGELOG_PATH=CHANGELOG.md
CHANGELOG_CHANGES=CHANGES.md

# github => version
GITHUB_CHANGES=CHANGES.md
GITHUB_RELEASE_PREFIX="${PROJECT}-"
GITHUB_REPO="sschmid/bee"
GITHUB_ATTACHMENTS_ZIP=()
source "${HOME}/.bee/github.sh"

# version
VERSION_PATH=version.txt
