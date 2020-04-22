#!/bin/sh

# BEGIN lib
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
# shellcheck source=./jar-update-lib.sh
. "${SCRIPT_DIR}/jar-update-lib.sh"
# END lib

main() {
  [ -z "$1" ] || [ -z "$2" ] && { echo "Required arguments in order: new jar, old jar" >&2 && exit 1; }

  tmp_dir=$(mktemp -d -t .$$.XXXXXX)
  new_jar=$(readlink -f "$1")
  old_jar=$(readlink -f "$2")
  trap 'rm -rf "$tmp_dir"; trap - EXIT; exit' EXIT INT HUP TERM

  update_jar "${tmp_dir}" "${new_jar}" "${old_jar}"

  rm -rf "$tmp_dir"
  trap - EXIT INT HUP TERM
}

main "$@"

