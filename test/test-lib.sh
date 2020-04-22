#!/bin/sh

ARG_WRAP='##'
SED_SEP='%'
COLUMN_SEPARATOR='|'
ARG_SEPARATOR="${COLUMN_SEPARATOR}"

# Variable used to make script work on git bash.
# It does not work with \n somehow.
__LINE_SEPARATOR='
'

# Transforms arguments separated by ${ARG_SEPARATOR}
# into arguments separated by line.
#
# Args:
#   args: arguments in a single line separated by ${ARG_SEPARATOR}
# Output:
#   arguments separated by line.
separate_args() {
  echo "$1" | tr "${ARG_SEPARATOR}" "${__LINE_SEPARATOR}"
}

# Translates an argument table into a list of arguments.
#
# Args:
#   args_table: table of columns separated by ${COLUMN_SEPARATOR}.
#           The first row should be the names of the arguments.
#           It may have optional lines separating the data.
#           These should contain at least five consecutive dashes ("-----").
# Output:
#   list of a list of args to substitute the values of a template function.
#           Each line contains a list of arguments.
#           Arguments are separated by ${ARG_SEPARATOR}.
get_test_args_list() (
  args_table="$1"

  first_line="$(echo "${args_table}" | head -1)"
  arg_num=$(_get_arg_num "${first_line}")
  args_names="$(_get_args_names "${first_line}" "${arg_num}")"
  table_data="$(_get_table_data "${args_table}")"
  args_list="$(_get_args_of_table "${table_data}" "${args_names}")"

  echo "${args_list}"
)

_get_arg_num() (
  line="$1"

  column="start"
  arg_num=0
  while [ -n "${column}" ]; do
    column="$(_get_column_of_row "${line}" "$((arg_num + 1))")"
    arg_num="$((arg_num + 1))"
  done
  arg_num="$((arg_num - 1))"

  echo "${arg_num}"
)

_get_args_names() (
  line="$1"
  arg_num="$2"

  args_names=""
  for i in $(seq "${arg_num}"); do
    args_names="${args_names}$(_get_column_of_row "${line}" "${i}")${__LINE_SEPARATOR}"
  done

  echo "${args_names}"
)

_get_table_data() (
  table="$1"
  echo "${table}" |
      sed '1d' |
      grep --invert-match -- '-----'
)

_get_args_of_table() (
  table_data="$1"
  args_names="$2"
  arg_num=$(echo "${args_names}" | wc -l)

  args_list=""
  while IFS= read -r row; do
    args_list="${args_list}$(_get_args_of_row "${row}" "${args_names}")
"
  done <<EOF
${table_data}
EOF

  echo "${args_list}"
)

_get_args_of_row() (
  row="$1"
  args_names="$2"
  arg_num=$(echo "${args_names}" | wc -l)

  args=""
  for i in $(seq "${arg_num}"); do
    arg_name="$(echo "${args_names}" | sed -n "${i}p")"
    arg_value="$(_get_column_of_row "${row}" "${i}")"
    args="${args}${arg_name}=${arg_value}|"
  done

  echo "${args}" | sed 's/|$//'
)

_get_column_of_row() (
  row="$1"
  column="$(($2 + 1))"
  echo "${row}" |
      cut -d"${COLUMN_SEPARATOR}" -f"${column}" |
      sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
)

# Generates functions based on a template and a list of arguments.
#
# Args:
#   template: function containing arguments surrounded by ${ARG_WRAP}.
#   args_list: list of args to substitute the values of template.
#           Each line should contain a list of arguments.
#           Arguments should be separated by ${ARG_SEPARATOR}.
# Output:
#   templates with their arguments substituted, separated by a line.
get_generated_tests() (
  template="$1"
  args_list="$2"
  arg_num=$(echo "${args_list}" | wc -l)

  for i in $(seq "${arg_num}"); do
    args="$(separate_args "$(echo "${args_list}" | sed -n "${i}p")")"
    _get_generated_test "${template}" "${args}"
    echo
  done
)

_get_generated_test() (
  template="$1"
  args="$2"

  while IFS= read -r arg; do
    arg_name=$(echo "${arg}" |
        cut -d'=' -f 1 |
        sed "s${SED_SEP}.*${SED_SEP}${ARG_WRAP}&${ARG_WRAP}${SED_SEP}")
    arg_value=$(echo "${arg}" | cut -d'=' -f 2)
    template=$(echo "${template}" |
        sed "s${SED_SEP}${arg_name}${SED_SEP}${arg_value}${SED_SEP}")
  done <<EOF
${args}
EOF
  echo "${template}"
)

# Generates a function which adds the tests to the test suite.
#
# Args:
#   tests: the script containing only the test functions.
# Output:
#   a function adding the tests to the suit.
get_suite() (
  tests="$1"
  cat <<EOF
suite() {
$(_get_suite_add_tests "${tests}")
}
EOF
)

_get_suite_add_tests() (
  tests="$1"
  echo "${tests}" |
      grep -E "[0-9a-zA-Z_-]+\(\)" |
      sed 's/^\(.*\)().*$/  suite_addTest "\1"/'
)

