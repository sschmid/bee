setup() {
  load 'test-helper.bash'
}

_tree() {
  local indent="$1"; shift
  local -a plugins=("$@")
  local plugin_name plugin_deps bullet
  local -i i n=${#plugins[@]}
  for (( i = 0; i < n; i++ )); do
    plugin_name="${plugins[i]%% *}"
    plugin_deps="${plugins[i]#* }"
    (( i == n - 1 )) && bullet="└── " || bullet="├── "
    echo "${indent}${bullet}${plugin_name}"
#    echo "${indent}${bullet}${plugin_name}" >&3
    if [[ "${plugin_name}" != "${plugin_deps}" ]]; then
      if (( i == n - 1 )); then
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
  cat << 'EOF' | assert_output -
├── a
├── b
└── c
EOF
}

@test "one element, one indent" {
  run _tree "" "a aa"
  cat << 'EOF' | assert_output -
└── a
    └── aa
EOF
}

@test "multiple elements, one indent" {
  run _tree "" "a aa" "b ba" "c ca"
  cat << 'EOF' | assert_output -
├── a
│   └── aa
├── b
│   └── ba
└── c
    └── ca
EOF
}

@test "multiple elements with deps, one indent" {
  run _tree "" "a aa ab ac" "b ba bb bc" "c ca cb cc"
  cat << 'EOF' | assert_output -
├── a
│   ├── aa
│   ├── ab
│   └── ac
├── b
│   ├── ba
│   ├── bb
│   └── bc
└── c
    ├── ca
    ├── cb
    └── cc
EOF
}
