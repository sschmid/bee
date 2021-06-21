#!/usr/bin/env bash

bee::help() {
  cat << EOF
🐝 bee $(cat "${BEE_HOME}/version.txt") - plugin-based bash automation

usage:
bee [-h | --help] [--version] [-q | --quiet] [-v | --verbose] <command> [<args>]

  job <title> <command>       run command as a job

examples:
  bee version bump_minor
  bee changelog merge
  bee github me
EOF
}
