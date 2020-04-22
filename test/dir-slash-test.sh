#!/bin/sh

get_dir_test_template() {
  cat <<EOF
test_dir_${ARG_WRAP}test_name${ARG_WRAP}() (
  dir="${ARG_WRAP}input${ARG_WRAP}"
  expected="${ARG_WRAP}expected${ARG_WRAP}"
  assertEquals "\${expected}" "\$(dir_name_without_last_slash "\${dir}")"
)
EOF
}

get_dir_test_args() {
  cat <<EOF
| test_name               | input           | expected        |
| ----------------------- | --------------- | --------------- |
| with_last_slash         | /test/last/dir/ | /test/last/dir  |
| without_last_slash      | /test/last/dir  | /test/last/dir  |
| relative_with_slash     | relative/       | relative        |
| relative_without_slash  | relative        | relative        |
EOF
}

generate_tests() (
  template="$(get_dir_test_template)"
  args_list="$(get_test_args_list "$(get_dir_test_args)")"
  tests="$(get_generated_tests "${template}" "${args_list}")"
  suite="$(get_suite "${tests}")"

  cat > "${SCRIPT_DIR}/${SCRIPT_NAME}-generated.sh" <<EOF
#!/bin/sh

${tests}

${suite}

. "${SRC_DIR:?No source dir found.}/jar-update-lib.sh"
. shunit2
EOF
)

main() {
  SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
  SCRIPT_NAME="$(basename "$0" .sh)"
  # shellcheck source=./test-lib.sh
  . "${TEST_DIR:?No test dir found.}/test-lib.sh"

  echo "Generating ${SCRIPT_NAME}"
  generate_tests
}

main

