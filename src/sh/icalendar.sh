# iCalendar modification wrapper
# - __edit
# - __new
# - __delete
# - __import_to_collection
# - __cancel_toggle
# - __tentative_toggle
# - __add_attachment

# Edit iCalendar file.
#
# @input $1: Start date/date-time
# @input $2: End date/date-time
# @input $3: Path to iCalendar file (relative to `$ROOT`)
__edit() {
  start=$(__datetime_human_machine "$1")
  end=$(__datetime_human_machine "$2")
  fpath="$ROOT/$3"
  location=$(awk -v field="LOCATION" "$AWK_GET" "$fpath" | tr -d "\n")
  summary=$(awk -v field="SUMMARY" "$AWK_GET" "$fpath" | tr -d "\n")
  description=$(awk -v field="DESCRIPTION" "$AWK_GET" "$fpath")
  filetmp=$(mktemp --suffix='.md')
  printf "::: |> %s\n::: <| %s\n" "$start" "$end" >"$filetmp"
  if [ -n "$location" ]; then
    printf "@ %s\n" "$location" >>"$filetmp"
  fi
  printf "# %s\n\n%s\n" "$summary" "$description" >>"$filetmp"
  checksum=$(cksum "$filetmp")
  $EDITOR "$filetmp" >/dev/tty

  # Update only if changes are detected
  if [ "$checksum" != "$(cksum "$filetmp")" ]; then
    filenew="$filetmp.ics"
    if awk "$AWK_UPDATE" "$filetmp" "$fpath" >"$filenew"; then
      mv "$filenew" "$fpath"
      if [ -n "${GIT:-}" ]; then
        $GIT add "$fpath"
        $GIT commit -q -m "Modified event '$(__summary_for_commit "$fpath") ...'" -- "$fpath"
      fi
      __refresh_data
    else
      rm -f "$filenew"
      err "Failed to edit entry. Press <enter> to continue."
      read -r tmp
    fi
  fi
  rm "$filetmp"
}

# Generate new iCalendar file
#
# This function also sets the `$start` variable to the start of the new entry.
# On failure, start will be empty.
#
# If some start has been specified and the nanoseconds are not 0, we assume
# that the user entered "tomorrow" or something like that, and did not
# specify the time. So, we will use the `$DAY_START` time of that date.
# If the user specified a malformed date/date-time, we fail.
#
# @input $1 (optional): Date or datetime, defaults to today.
__new() {
  collection=$(echo "$COLLECTION_LABELS" | tr ';' '\n' | awk '/./ {print}' | $FZF --margin="30%" --no-info --delimiter='=' --with-nth=2 --accept-nth=1)
  fpath=""
  while [ -f "$fpath" ] || [ -z "$fpath" ]; do
    uuid=$($UUIDGEN)
    fpath="$ROOT/$collection/$uuid.ics"
  done
  d="today $DAY_START"
  if [ -n "${1:-}" ]; then
    d="$1"
    if [ "$(date -d "$1" +"%N")" -ne 0 ]; then
      d="$d $DAY_START:00"
    fi
  fi
  startsec=$(date -d "$d" +"%s")
  endsec=$((startsec + 3600))
  start=$(__datetime_human_machine "$startsec")
  end=$(__datetime_human_machine "$endsec")
  filetmp=$(mktemp --suffix='.md')
  (
    echo "::: |> $start"
    echo "::: <| $end"
    echo "@ <!-- write location here, optional line -->"
    echo "# <!-- write summary here -->"
    echo ""
  ) >"$filetmp"
  checksum=$(cksum "$filetmp")
  $EDITOR "$filetmp" >/dev/tty

  # Update only if changes are detected
  if [ "$checksum" != "$(cksum "$filetmp")" ]; then
    filenew="$filetmp.ics"
    if awk -v uid="$uuid" "$AWK_NEW" "$filetmp" >"$filenew"; then
      mv "$filenew" "$fpath"
      if [ -n "${GIT:-}" ]; then
        $GIT add "$fpath"
        $GIT commit -q -m "Added event '$(__summary_for_commit "$fpath") ...'" -- "$fpath"
      fi
      start=$(awk -v field="DTSTART" "$AWK_GET" "$fpath" | grep -o '[0-9]\{8\}')
    else
      rm -f "$filenew"
      start=""
      err "Failed to create new entry. Press <enter> to continue."
      read -r tmp
    fi
  fi
  rm "$filetmp"
}

# Delete iCalendar file
#
# @input $1: Path to iCalendar file, relative to `$ROOT`
__delete() {
  fpath="$ROOT/$1"
  summary=$(awk -v field="SUMMARY" "$AWK_GET" "$fpath")
  while true; do
    printf "Do you want to delete the entry with the title \"%s\"? (yes/no): " "$summary" >/dev/tty
    read -r yn
    case $yn in
    "yes")
      sfg="$(__summary_for_commit "$fpath")"
      rm -v "$fpath"
      if [ -n "${GIT:-}" ]; then
        $GIT add "$fpath"
        $GIT commit -q -m "Deleted event '$sfg ...'" -- "$fpath"
      fi
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
}

# Import iCalendar file to specified collection. The only modification made to
# the file is setting the UID.
#
# @input $1: path to iCalendar file
# @input $2: collection name
__import_to_collection() {
  file="$1"
  collection="$2"
  fpath=""
  while [ -f "$fpath" ] || [ -z "$fpath" ]; do
    uuid=$($UUIDGEN)
    fpath="$ROOT/$collection/$uuid.ics"
  done
  filetmp=$(mktemp)
  awk -v field="UID" -v value="$uuid" "$AWK_SET" "$file" >"$filetmp"
  mv "$filetmp" "$fpath"
  if [ -n "${GIT:-}" ]; then
    $GIT add "$fpath"
    $GIT commit -q -m "Imported event '$(__summary_for_commit "$fpath") ...'" -- "$fpath"
  fi
}

# Set status of appointment to CANCELLED or CONFIRMED (toggle)
#
# @input $1: path to iCalendar file
__cancel_toggle() {
  fpath="$ROOT/$1"
  status=$(awk -v field="STATUS" "$AWK_GET" "$fpath")
  newstatus="CANCELLED"
  if [ "${status:-}" = "$newstatus" ]; then
    newstatus="CONFIRMED"
  fi
  filetmp=$(mktemp)
  awk -v field="STATUS" -v value="$newstatus" "$AWK_SET" "$fpath" >"$filetmp"
  mv "$filetmp" "$fpath"
  if [ -n "${GIT:-}" ]; then
    $GIT add "$fpath"
    $GIT commit -q -m "Event '$(__summary_for_commit "$fpath") ...' has now status $status" -- "$fpath"
  fi
}

# Toggle status flag: CONFIRMED <-> TENTATIVE
#
# @input $1: path to iCalendar file
__tentative_toggle() {
  fpath="$ROOT/$1"
  status=$(awk -v field="STATUS" "$AWK_GET" "$fpath")
  newstatus="TENTATIVE"
  if [ "${status:-}" = "$newstatus" ]; then
    newstatus="CONFIRMED"
  fi
  filetmp=$(mktemp)
  awk -v field="STATUS" -v value="$newstatus" "$AWK_SET" "$fpath" >"$filetmp"
  mv "$filetmp" "$fpath"
  if [ -n "${GIT:-}" ]; then
    $GIT add "$fpath"
    $GIT commit -q -m "Event '$(__summary_for_commit "$fpath") ...' has now status $status" -- "$fpath"
  fi
}

# Prepend attachment to iCalendar file
#
# @input $1: path to iCalendar file
__add_attachment() {
  fpath="$ROOT/$1"
  sel=$(
    $FZF --prompt="Select attachment> " \
      --walker="file,hidden" \
      --walker-root="$HOME" \
      --expect="ctrl-c,ctrl-g,ctrl-q,esc"
  )
  key=$(echo "$sel" | head -1)
  f=$(echo "$sel" | tail -1)
  if [ -n "$key" ]; then
    f=""
  fi
  if [ -z "$f" ] || [ ! -f "$f" ]; then
    return
  fi
  filename=$(basename "$f")
  mime=$(file -b -i "$f" | cut -d ';' -f 1)
  if [ -z "$mime" ]; then
    mime="application/octet-stream"
  fi
  fenc=$(mktemp)
  base64 "$f" >"$fenc"
  filetmp=$(mktemp)
  awk -v file="$fenc" -v mime="$mime" -v filename="$filename" "$AWK_ATTACH" "$fpath" >"$filetmp"
  mv "$filetmp" "$fpath"
  if [ -n "${GIT:-}" ]; then
    $GIT add "$fpath"
    $GIT commit -q -m "Added attachment to '$(__summary_for_commit "$fpath") ...'" -- "$fpath"
  fi
  rm "$fenc"
}
