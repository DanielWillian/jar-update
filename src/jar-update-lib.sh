#!/bin/sh

dir_name_without_last_slash() {
  echo "$1" | sed -e 's/\/$//'
}

differ_or_new_files() (
  new_dir=$(dir_name_without_last_slash "$1")
  old_dir=$(dir_name_without_last_slash "$2")

  changes=$(diff -qr "${new_dir}/" "${old_dir}/" | grep "${new_dir}/" | tee /dev/tty)
  differ=$(echo "$changes" | sed -n -e "s%^Files ${new_dir}\/\(.*\) and .* differ%\1%p")
  new_file=$(echo "$changes" | sed -n -e "s%Only in ${new_dir}\/: \(.*\)%\1%p")
  new_sub_dir=$(echo "$changes" | sed -n -e "s%Only in ${new_dir}\/\(.\+\): \(.*\)%\1\/\2%p")
  update=$(printf '%s\n%s\n%s' "${differ}" "${new_file}" "${new_sub_dir}" |
      tr '\n' ' ' |
      sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
  echo "${update}"
)

extract_jars() (
  tmp_dir=$(dir_name_without_last_slash "$(readlink -f "$1")")
  new_jar=$(readlink -f "$2")
  old_jar=$(readlink -f "$3")

  mkdir -p "${tmp_dir}/new" "${tmp_dir}/old"
  old_path=$(pwd)
  cd "${tmp_dir}/new" || return 1
  jar xvf "${new_jar}" 1>/dev/null
  cd "${tmp_dir}/old" || return 1
  jar xvf "${old_jar}" 1>/dev/null
  cd "${old_path}" || return 1
)

move_files() (
  files="$1"
  new_dir=$(dir_name_without_last_slash "$2")
  old_dir=$(dir_name_without_last_slash "$3")

  if [ -n "${files}" ]; then
    for file in ${files}; do
      mv "${new_dir}/${file}" "${old_dir}/${file}" || return 1
    done
  fi
)

update_old_jar() (
  tmp_dir=$(dir_name_without_last_slash "$(readlink -f "$1")")
  old_jar=$(readlink -f "$2")
  updated_files="$3"

  old_path=$(pwd)
  cp "$old_jar" "$tmp_dir/old"
  cd old  || return 1
  old_jar_name="$(basename "${old_jar}")"
  # shellcheck disable=2086
  jar uvf "${old_jar_name}" ${updated_files}
  old_jar_dir="$(dirname "${old_jar}")"
  cp "${old_jar_name}" "${old_jar_dir}/$(basename "${old_jar_name}" ".jar")-new.jar"
  cd "${old_path}" || return 1
)

update_jar() (
  tmp_dir=$(dir_name_without_last_slash "$(readlink -f "$1")")
  new_jar=$(readlink -f "$2")
  old_jar=$(readlink -f "$3")

  old_path=$(pwd)
  extract_jars "${tmp_dir}" "${new_jar}" "${old_jar}" || return 1
  cd "${tmp_dir}" || return 1
  update=$(differ_or_new_files "new" "old")
  move_files "${update}" "new" "old" || return 1
  update_old_jar "${tmp_dir}" "${old_jar}" "${update}" || return 1

  cd "${old_path}" || return 1
)

