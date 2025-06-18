# Extra command-line options
# - --import-ni
# - --import
# - --git
# - --git-init

# Import iCalendar file noninteractively
#
# @input $2: Absolute path to iCalendar file
# @input $3: Collection
# @return: On success, returns 0, otherwise 1
if [ "${1:-}" = "--import-ni" ]; then
  shift
  file="${1:-}"
  collection="${2:-}"
  if [ ! -f "$file" ]; then
    err "File \"$file\" does not exist"
    exit 1
  fi
  for c in $(echo "$COLLECTION_LABELS" | sed "s|=[^;]*;| |g"); do
    if [ "$collection" = "$c" ]; then
      cexists="yes"
      break
    fi
  done
  if [ -n "${cexists:-}" ] && [ -d "$ROOT/$collection" ]; then
    __import_to_collection "$file" "$collection"
  else
    err "Collection \"$collection\" does not exist"
    exit 1
  fi
  exit
fi

# Import iCalendar file.
#
# @input $2: Absolute path to iCalendar file
# @return: On success, returns 0, otherwise 1
if [ "${1:-}" = "--import" ]; then
  shift
  file="${1:-}"
  if [ ! -f "$file" ]; then
    err "File \"$file\" does not exist"
    return 1
  fi
  line=$(awk \
    -v collection_labels="$COLLECTION_LABELS" \
    "$AWK_PARSE" "$file")
  set -- $line
  startsec="${1:-}"
  endsec="${2:-}"
  if [ -z "$line" ] || [ -z "$startsec" ] || [ -z "$endsec" ]; then
    err "File \"$file\" does not look like an iCalendar file containing an event"
    return 1
  fi
  start=$(__datetime_human_machine "$startsec")
  end=$(__datetime_human_machine "$endsec")
  location=$(awk -v field="LOCATION" "$AWK_GET" "$file")
  summary=$(awk -v field="SUMMARY" "$AWK_GET" "$file")
  description=$(awk -v field="DESCRIPTION" "$AWK_GET" "$file")
  filetmp=$(mktemp --suffix='.md')
  (
    echo "::: |> $start"
    echo "::: <| $end"
  ) >"$filetmp"
  if [ -n "$location" ]; then
    echo "@ $location" >>"$filetmp"
  fi
  (
    echo "# $summary"
    echo ""
    echo "$description"
  ) >>"$filetmp"
  $CAT "$filetmp" >/dev/tty
  while true; do
    printf "Do you want to import this entry? (yes/no): " >/dev/tty
    read -r yn
    case $yn in
    "yes")
      collection=$(echo "$COLLECTION_LABELS" | tr ';' '\n' | awk '/./ {print}' | $FZF --margin="30%" --no-info --delimiter='=' --with-nth=2 --accept-nth=1)
      if [ -z "$collection" ]; then
        exit
      fi
      __import_to_collection "$file" "$collection"
      break
      ;;
    "no")
      break
      ;;
    *)
      echo "Please answer \"yes\" or \"no\"." >/dev/tty
      ;;
    esac
  done
  rm -f "$filetmp"
  exit
fi

# Run git command
#
# @input $2..: Git command
# @return: On success, returns 0, otherwise 1
if [ "${1:-}" = "--git" ]; then
  if [ -z "${GIT:-}" ]; then
    err "Git not supported, run \`$0 --git-init\` first"
    return 1
  fi
  shift
  $GIT "$@"
  exit
fi

# Enable the ues of git
#
# @return: On success, returns 0, otherwise 1
if [ "${1:-}" = "--git-init" ]; then
  if [ -n "${GIT:-}" ]; then
    err "Git already enabled"
    return 1
  fi
  if ! command -v "git" >/dev/null; then
    err "Git command not found"
    return 1
  fi
  git -C "$ROOT" init
  git -C "$ROOT" add -A
  git -C "$ROOT" commit -m 'Initial commit: Start git tracking'
  exit
fi
