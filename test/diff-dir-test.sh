#!/bin/sh

get_tmp_dir_one_time_set_up() {
  cat <<EOF
oneTimeSetUp() {
  tmp_dir=\${SHUNIT_TMPDIR}
  echo "\${tmp_dir:?temp dir is not set}" >/dev/null
}
EOF
}

get_tmp_dir_set_up() {
  cat <<EOF
setUp() {
  new_dir="\${tmp_dir:?}"/new
  old_dir="\${tmp_dir:?}"/old
  rm -rf "\${new_dir}" "\${old_dir}"
  mkdir -p "\${new_dir}/a"
  mkdir -p "\${old_dir}/a"
}
EOF
}

get_diff_mocks() {
  cat <<EOF
set -a
tee() {
  cat
}
set +a
EOF
}

get_diff_test_template() {
  cat <<EOF
test_diff_${ARG_WRAP}test_name${ARG_WRAP}() {
  echo "${ARG_WRAP}file_1${ARG_WRAP}" > \
"\${tmp_dir}/new/${ARG_WRAP}name_1${ARG_WRAP}"
  echo "${ARG_WRAP}file_2${ARG_WRAP}" > \
"\${tmp_dir}/new/${ARG_WRAP}name_2${ARG_WRAP}"
  echo "${ARG_WRAP}file_3${ARG_WRAP}" > \
"\${tmp_dir}/old/${ARG_WRAP}name_3${ARG_WRAP}"
  echo "${ARG_WRAP}file_4${ARG_WRAP}" > \
"\${tmp_dir}/old/${ARG_WRAP}name_4${ARG_WRAP}"
  assertEquals "${ARG_WRAP}expected${ARG_WRAP}" \
"\$(differ_or_new_files "\${tmp_dir}/new" "\${tmp_dir}/old")"
}
EOF
}

get_diff_test_args() {
  cat <<EOF
| test_name | file_1 | name_1 | file_2 | name_2 | file_3 | name_3 | file_4 | name_4 | expected |
| no_diff   | abc    | abc    | def    | def    | abc    | abc    | def    | def    |          |
| diff_file | abcd   | abc    | def    | def    | abc    | abc    | def    | def    | abc      |
| new_file  | abcd   | abcd   | def    | def    | abc    | abc    | def    | def    | abcd     |
| old_file  | abc    | abc    | abc    | abc    | abc    | abc    | def    | def    |          |
| diff_dir  | abcd   | a/abc  | def    | def    | abc    | a/abc  | def    | def    | a/abc    |
| new_dir   | abcd   | a/abc  | def    | def    | abc    | abc    | def    | def    | a/abc    |
| old_dir   | abcd   | abc    | abc    | abc    | abc    | abc    | a/def  | a/def  |          |
EOF
}

generate_tests() (
  template="$(get_diff_test_template)"
  args_list="$(get_test_args_list "$(get_diff_test_args)")"
  tests="$(get_generated_tests "${template}" "${args_list}")"
  suite="$(get_suite "${tests}")"

  cat > "${SCRIPT_DIR}/${SCRIPT_NAME}-generated.sh" <<EOF
#!/bin/sh

$(get_tmp_dir_one_time_set_up)

$(get_tmp_dir_set_up)

$(get_diff_mocks)

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

