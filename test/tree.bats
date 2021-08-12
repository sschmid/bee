setup() {
  load 'test-helper.bash'
}

_tree() {
  local indent="$1"
  shift
  local -a plugins=("$@")
  local plugin_name plugin_deps bullet
  local -i i n=${#plugins[@]}
  for ((i = 0; i < n; i++)); do
    plugin_name="${plugins[i]%% *}"
    plugin_deps="${plugins[i]#* }"
    if ((i == n - 1)); then bullet="└── "; else bullet="├── "; fi
    echo "${indent}${bullet}${plugin_name}"
#    echo "${indent}${bullet}${plugin_name}" >&3
    if [[ "${plugin_name}" != "${plugin_deps}" ]]; then
      if ((i == n - 1)); then
        # shellcheck disable=SC2086
        _tree "${indent}    " ${plugin_deps}
      else
        # shellcheck disable=SC2086
        _tree "${indent}│   " ${plugin_deps}
      fi
    fi
  done
}

@test "one element" {
  run _tree "" a
  assert_output "└── a"
}

@test "multiple elements" {
  run _tree "" a b c
  assert_line --index 0 "├── a"
  assert_line --index 1 "├── b"
  assert_line --index 2 "└── c"
}

@test "one element, one indent" {
  run _tree "" "a aa"
  assert_line --index 0 "└── a"
  assert_line --index 1 "    └── aa"
}

@test "multiple elements, one indent" {
  run _tree "" "a aa" "b ba" "c ca"
  assert_line --index 0 "├── a"
  assert_line --index 1 "│   └── aa"
  assert_line --index 2 "├── b"
  assert_line --index 3 "│   └── ba"
  assert_line --index 4 "└── c"
  assert_line --index 5 "    └── ca"
}

@test "multiple elements with deps, one indent" {
  run _tree "" "a aa ab ac" "b ba bb bc" "c ca cb cc"
  assert_line --index 0  "├── a"
  assert_line --index 1  "│   ├── aa"
  assert_line --index 2  "│   ├── ab"
  assert_line --index 3  "│   └── ac"
  assert_line --index 4  "├── b"
  assert_line --index 5  "│   ├── ba"
  assert_line --index 6  "│   ├── bb"
  assert_line --index 7  "│   └── bc"
  assert_line --index 8  "└── c"
  assert_line --index 9  "    ├── ca"
  assert_line --index 10 "    ├── cb"
  assert_line --index 11 "    └── cc"
}
