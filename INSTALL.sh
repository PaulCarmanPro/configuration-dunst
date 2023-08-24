#! /bin/bash
#shellcheck disable=SC2155 # declare and assign separately

declare dSource="$(dirname -- "${BASH_SOURCE[0]}")"
"$dSource/MakeLinks.sh" "$HOME" "$dSource/home"
