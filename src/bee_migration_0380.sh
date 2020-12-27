#!/usr/bin/env bash
# Dec 2020

command -v builtin_commands &> /dev/null || {
  builtin_commands() {
    internal_commands
  }
}
