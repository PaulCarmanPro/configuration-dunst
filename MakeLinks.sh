#! /bin/bash
#
# MakeLinks.sh -FLAG... DESTINATION_DIRECTORY SOURCE...

# MakeLinks installs SOURCE by creating links in DESTINATION_DIRECTORY.
# DESTINATION_DIRECTORY is created even if SOURCES do not exist.
# Links to files are created recursively from SOURCE_DIRECTORY.
# Competing files/directories are left, backed, overwritten according to flags.

# Note: INLINE means that flags apply to following arguments
# -b|--backup = make backup while creating following links (default)
# -c|--clean = backup/overwrite existing directories (opposite of -m)
# -d|--directory = next argument is DESTINATION_DIRECTORY (initially assumed)
# -e|--equal = allow equal file to remain in source (opposite of -l)
# -f|--force = force overwrite while creating following links (opposite of -b)
# -m|--mix = mix links with existing files (default)
# -o|--overlink = force link even if destination is identical to source (default)
# -q|--quiet = keep quiet unless error (opposite of -v)
# -v|--verbose = describe what is happening (default)

#shellcheck disable=SC2155 # declare and assign separately
#shellcheck disable=SC2086 # doublequote to prevent splitting

set -f # no filename expansion (globbing)

declare dClean # replace existing directories
declare dOverlink=o # write a link over an identical file
declare dOverwrite # activate via -f|--force
declare dVerbose=v # default verbose unless -q|--quiet

declare dErr # many sources lacking destination dump many identical errors
Err() {
   local zErr="$(printf '!!![%s]!!! %s\n' "${BASH_SOURCE[0]}" "$1")"
   [[ 2 -ge "$#" ]] \
      && zErr+="$(printf '%s\n' "${@:2}")"
   if [[ "$zErr" != "$dErr" ]]; then
      >&2 printf '%s' "$zErr"
      dErr="$zErr"
   fi
}

Note() {
   >&2 printf '# %s\n' "$@"
}

CreateDirectory() { # PATH
   # the contents of an existing directory are left alone
   # allow user to have/keep extra files not in repository
   local zDest="$1"
   if [[ -d "$zDest" ]]; then
      [[ "$dVerbose" ]] && Note "Directory exists at $zDest"
      return
   elif [[ -e "$zDest" ]]; then
      if cmp "$zDest" "$zDest~" 2>/dev/null; then
         [[ "$dVerbose" ]] && Note "Already backed up..."
         rm "$zDest"
      elif [[ "$dOverwrite" ]]; then
         [[ "$dVerbose" ]] && Note "Overwriting..."
         rm -rf$dVerbose "$zDest"
      else
         [[ "$dVerbose" ]] && Note "Backing up..."
         mv -b$dVerbose "$zDest" "$zDest~"
      fi
   fi
   [[ "$dVerbose" ]] && Note "Creating directory..."
   mkdir -p$dVerbose "$zDest"
}

CreateLink() { # SOURCE=File DEST=FutureLink
   # create a symbolic link to zSource at zDest
   # unless zDest is identical to zSource, then the file will remain
   # create backup of original if aFlags doesnot contain f
   local zSource="$1"
   local zDest="$2"
   if [[ -L "$zDest" ]]; then
      if [[ "$(readlink "$zDest")" = "$zSource" ]]; then
         [[ "$dVerbose" ]] && Note "Link exists at $zDest"
      else
         [[ "$dVerbose" ]] && Note "Replacing link..."
         ln -${dVerbose}fsT "$zSource" "$zDest"
      fi
   else
      if [[ -e "$zDest" ]]; then
         if cmp "$zDest" "$zSource" 2>/dev/null; then
            if [[ "$dOverlink" ]]; then
               [[ "$dVerbose" ]] && Note "Replacing identical..."
               rm -r$dVerbose "$zDest"
            else
               [[ "$dVerbose" ]] && Note "Leaving identical $zSource."
               return 0
            fi
         elif cmp "$zDest" "$zDest~" 2>/dev/null; then
            [[ "$dVerbose" ]] && Note "Already backed up..."
            rm -r "$zDest"
         elif [[ "$dOverwrite" ]]; then # flags force overwrite
            [[ "$dVerbose" ]] && Note "Overwriting..."
            rm -r$dVerbose "$zDest"
         else
            [[ "$dVerbose" ]] && Note "Backing up..."
            mv -b$dVerbose "$zDest" "$zDest~" # create backup
         fi
      elif [[ ! -e "$(dirname "$zDest")" ]]; then
         CreateDirectory "$(dirname "$zDest")"
      fi
      [[ "$dVerbose" ]] && Note "Creating link..."
      ln -${dVerbose}sT "$zSource" "$zDest"
   fi
}

CreateLinks() { # DEST=Directory < SOURCES_NULL_TERMINATED
   local aDest="${1%/}"
   local z zDest zSource
   while IFS= read -r -d $'\0' z; do
      zDest="$aDest${z:+/}$z"
      zSource="${aSource%/}${z:+/}$z"
      if [[ -d "$zSource" ]]; then
         CreateDirectory "$zDest" \
            || Err "Could not create destination directory ${aDest@Q}"
      else
         CreateLink "$zSource" "$zDest" \
            || Err "Could not create link from ${zDest@Q} to ${zSource@Q}"
      fi
   done
}

ProcessFlags() { # ARG
   local zFlag="$1"
   while :; do
      case "$zFlag" in
         -b*|--backup) dOverwrite= ;; # create backup~ before overwrite
         -d*|--destination) unset aDest ;; # assign destination next iteration
         -e*|--equal) dOverlink= ;; # leave existing identical
         -f*|--force) dOverwrite=f ;; # overwrite without backup
         -o*|--overlink) dOverlink=o ;; # overwrite identical with link
         -q*|--quiet) dVerbose= ;;
         -v*|--verbose) dVerbose=v ;;
         --) aDash=-- ;;
         *) Err "Unknown flag ${zFlag@Q}."
            exit 1
      esac
      [[ '--' = "${zFlag:0:2}" ]] && break
      zFlag="-${zFlag:2}"
      [[ '-' = "$zFlag" ]] && break
   done
}

declare aSource
declare a # current loop argument
declare aDash # set if -- has been found
unset aDest # unset is the flag to reassign aDest 
declare zDest # back-checked for over-rename error
while [[ 0 != "$#" ]]; do
   a="$1"
   shift # allow continue and extra argument consumption (neither are used)
   if [[ -z "$aDash" && '-' = "${a:0:1}" ]]; then
      ProcessFlags "$a"
   elif [[ -z "${aDest+x}" ]]; then # reassign destination
      declare aDest="${a%/}"
   else # recursively create links to files found in source
      if ! aSource="$(realpath -e "$a")"; then
         Err "Could not resolve source path ${aSource@Q}."
      elif [[ "$aDest" = "$aSource" ]]; then
         Err "Destination identical to source ${aSource@Q}."
      else # loop through found files (will ignore empty directories)
         CreateLinks "$aDest"  \
                     < <(find "$aSource" -type f -printf '%P\0' | sort -zV)
      fi
   fi
done

