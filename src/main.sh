#!/bin/sh

set -eu
# TODO: Make sensitive to failures. I don't want to miss appointments!
# TODO Ensure safe use of delimiters

if [ "${1:-}" = "--help" ]; then
  echo "Usage: $0 [OPTION]"
  echo ""
  echo "You may specify at most one option."
  echo "  --help                 Show this help and exit"
  echo "  --today                Show today's appointments"
  echo "  --yesterday            Show yesterday's appointments"
  echo "  --tomorrow             Show tomorrow's appointments"
  echo "  --goto                 Interactively enter date to jump to"
  echo "  --new [date/date-time] Create new entry (today)"
  echo "  --day [date]           Show appointments of specified day (today)"
  echo "  --week [date]          Show week of specified date (today)"
  echo "  --import file          Import iCalendar file"
  echo "  --git cmd              Run git command cmd relative to calendar root"
  echo "  --git-init             Enable the use of git"
  echo ""
  echo "You may also start this program with setting locale and timezone"
  echo "information. For instance, to see and modify all of your calendar"
  echo "entries from the perspective of Saigon, run"
  echo "TZ='Asia/Saigon' $0"
  echo "Likewise, you may specify the usage of Greek with"
  echo "LC_TIME=el_GR.UTF-8 $0"
  exit
fi

###
### Helper functions
###   err
###

# err()
# This is a helper function to print errors.
#
# @input $1: Error message
err() {
  echo "❌ $1" >/dev/tty
}

###
### preview helper functions
###   month_previous
###   month_next
###   datetime_str
###

# month_previous()
# Print previous month of specified input month as <month> <year>.
#
# @input $1: Month
# @input $2: Year
month_previous() {
  month=$(echo "$1" | sed 's/^0//')
  year=$(echo "$2" | sed 's/^0//')
  if [ "$month" -eq 1 ]; then
    month=12
    year=$((year - 1))
  else
    month=$((month - 1))
  fi
  echo "$month $year"
}

# month_next()
# Print next month of specified input month as <month> <year>.
#
# @input $1: Month
# @input $2: Year
month_next() {
  month=$(echo "$1" | sed 's/^0//')
  year=$(echo "$2" | sed 's/^0//')
  if [ "$month" -eq 12 ]; then
    month=1
    year=$((year + 1))
  else
    month=$((month + 1))
  fi
  echo "$month $year"
}

# datetime_str()
# Print date or datetime in a human readable form.
#
# @input $1:              Seconds since epoch
# @input $2.. (optoinal): Prepend date format
datetime_str() {
  s="$1"
  shift
  t=$(date -d "@$s" +"%R")
  dfmt="$*%e %b %Y"
  if [ "$t" != "00:00" ]; then
    dfmt="$dfmt %R %Z"
  fi
  date -d "@$s" +"$dfmt"
}

###
### Preview command-line options
###   --preview-event
###   --preview_week
###

# --preview-event
# Print preview of event and exit.
#
# @input $1: Line from day view containing an event
# @req $ROOT: Path that contains the collections (see configuration)
# @req $AWK_GET: Awk script to extract fields from iCalendar file
# @req $CAT: Program to print
# @req colors
if [ "${1:-}" = "--preview-event" ]; then
  hour=$(echo "$2" | cut -d '|' -f 2)
  start=$(echo "$2" | cut -d '|' -f 3)
  end=$(echo "$2" | cut -d '|' -f 4)
  fpath=$(echo "$2" | cut -d '|' -f 5 | sed "s/ /|/g")
  if [ -n "$hour" ] && [ -n "$fpath" ]; then
    fpath="$ROOT/$fpath"
    start=$(datetime_str "$start" "%a ")
    end=$(datetime_str "$end" "%a ")
    location=$(awk -v field="LOCATION" "$AWK_GET" "$fpath")
    echo "📅 ${CYAN}$start${OFF} → ${CYAN}$end${OFF}"
    if [ -n "${location:-}" ]; then
      echo "📍 ${CYAN}$location${OFF}"
    fi
    echo ""
    awk -v field="DESCRIPTION" "$AWK_GET" "$fpath" | $CAT
  fi
  exit
fi

# --preview-week
# Print preview of week.
#
# @input $2: Line from week view
# @req $AWK_CALSHIFT: Awk script to make `cal` output to start on Mondays
# @req $AWK_CALANNOT: Awk script to annotate calendar
if [ "${1:-}" = "--preview-week" ]; then
  sign=$(echo "$2" | cut -d '|' -f 1)
  if [ "$sign" = "+" ]; then
    startdate=$(echo "$2" | cut -d '|' -f 2)
    set -- $(date -d "$startdate" +"%Y %m %d")
    year=$1
    month=$2
    day=$3
    set -- $(date -d "today" +"%Y %m %d")
    year_cur=$1
    month_cur=$2
    day_cur=$3
    # Previous months
    set -- $(month_previous "$month" "$year")
    month_pre="$1"
    year_pre="$2"
    set -- $(month_previous "$month_pre" "$year_pre")
    month_pre2="$1"
    year_pre2="$2"
    # Next months
    set -- $(month_next "$month" "$year")
    month_nex="$1"
    year_nex="$2"
    set -- $(month_next "$month_nex" "$year_nex")
    month_nex2="$1"
    year_nex2="$2"
    set -- $(month_next "$month_nex2" "$year_nex2")
    month_nex3="$1"
    year_nex3="$2"
    # Highlight today
    if [ "$month_pre2" -eq "$month_cur" ] && [ "$year_pre2" -eq "$year_cur" ]; then
      var_pre2=$day_cur
    fi
    if [ "$month_pre" -eq "$month_cur" ] && [ "$year_pre" -eq "$year_cur" ]; then
      var_pre=$day_cur
    fi
    if [ "$month" -eq "$month_cur" ] && [ "$year" -eq "$year_cur" ]; then
      var=$day_cur
    fi
    if [ "$month_nex" -eq "$month_cur" ] && [ "$year_nex" -eq "$year_cur" ]; then
      var_nex=$day_cur
    fi
    if [ "$month_nex2" -eq "$month_cur" ] && [ "$year_nex2" -eq "$year_cur" ]; then
      var_nex2=$day_cur
    fi
    if [ "$month_nex3" -eq "$month_cur" ] && [ "$year_nex3" -eq "$year_cur" ]; then
      var_nex3=$day_cur
    fi
    # show
    (
      cal "$month_pre2" "$year_pre2" | awk "$AWK_CALSHIFT" | awk -v cur="${var_pre2:-}" "$AWK_CALANNOT"
      cal "$month_pre" "$year_pre" | awk "$AWK_CALSHIFT" | awk -v cur="${var_pre:-}" "$AWK_CALANNOT"
      cal "$month" "$year" | awk "$AWK_CALSHIFT" | awk -v cur="${var:-}" -v day="$day" "$AWK_CALANNOT"
      cal "$month_nex" "$year_nex" | awk "$AWK_CALSHIFT" | awk -v cur="${var_nex:-}" "$AWK_CALANNOT"
      cal "$month_nex2" "$year_nex2" | awk "$AWK_CALSHIFT" | awk -v cur="${var_nex2:-}" "$AWK_CALANNOT"
      cal "$month_nex3" "$year_nex3" | awk "$AWK_CALSHIFT" | awk -v cur="${var_nex3:-}" "$AWK_CALANNOT"
    ) | awk '{ l[NR%8] = l[NR%8] "    " $0 } END {for (i in l) if (i>0) print l[i] }'
  fi
  exit
fi

###
### View Functions
###   __view_day
###   __view_week
###   __view_all
###

# __view_day()
# This function prints the view for the day specified in `$DISPLAY_DATE`.
#
# @req $DISPLAY_DATE:      Specification of the day to show
# @req $WEEKLY_DATA_FILE:  Filename of weekly data (see `__refresh_data` and `__load_weeks`)
# @req $ROOT:              Path that contains the collections (see configuration)
# @req $COLLECTION_LABELS: Mapping between collections and lables (see configuration)
# @req $AWK_PARSE:         Parse awk script
# @req $DAY_START:         Start time of the day (see configuration)
# @req $DAY_END:           Start time of the day (see configuration)
# @req $AWK_DAYVIEW:       Day-view awk script
__view_day() {
  weeknr=$(date -d "$DISPLAY_DATE" +"%G.%V")
  files=$(grep "^$weeknr\ " "$WEEKLY_DATA_FILE" | cut -d " " -f 2-)
  # Find relevant files in list of week files
  sef=$({
    set -- $files
    for file in "$@"; do
      file="$ROOT/$file"
      awk \
        -v collection_labels="$COLLECTION_LABELS" \
        "$AWK_PARSE" "$file"
    done
  })
  today=$(date -d "$DISPLAY_DATE" +"%D")
  if [ -n "$sef" ]; then
    sef=$(echo "$sef" | while IFS= read -r line; do
      set -- $line
      starttime="$1"
      shift
      endtime="$1"
      shift
      fpath="$(echo "$1" | sed 's/|/ /g')" # we will use | as delimiter (need to convert back!)
      shift
      collection="$1"
      shift
      description="$(echo "$*" | sed 's/|/:/g')" # we will use | as delimiter
      #
      daystart=$(date -d "$today 00:00:00" +"%s")
      dayend=$(date -d "$today 23:59:59" +"%s")
      line=""
      if [ "$starttime" -gt "$daystart" ] && [ "$starttime" -lt "$dayend" ]; then
        s=$(date -d "@$starttime" +"%R")
      elif [ "$starttime" -le "$daystart" ] && [ "$endtime" -gt "$daystart" ]; then
        s="00:00"
      else
        continue
      fi
      if [ "$endtime" -gt "$daystart" ] && [ "$endtime" -lt "$dayend" ]; then
        e=$(date -d "@$endtime" +"%R")
      elif [ "$endtime" -ge "$dayend" ] && [ "$starttime" -lt "$dayend" ]; then
        e="00:00"
      else
        continue
      fi
      echo "$s|$e|$starttime|$endtime|$fpath|$collection|$description"
    done)
  fi
  echo "$sef" | sort -n | awk -v today="$today" -v daystart="$DAY_START" -v dayend="$DAY_END" "$AWK_DAYVIEW"
}

# __view_week()
# This function prints the view for the week that contains the day specified in `$DISPLAY_DATE`.
#
# @req $DISPLAY_DATE:      Specification of the day to show
# @req $WEEKLY_DATA_FILE:  Filename of weekly data (see `__refresh_data` and `__load_weeks`)
# @req $ROOT:              Path that contains the collections (see configuration)
# @req $COLLECTION_LABELS: Mapping between collections and lables (see configuration)
# @req $AWK_WEEKVIEW:      Week-view awk script
__view_week() {
  weeknr=$(date -d "$DISPLAY_DATE" +"%G.%V")
  files=$(grep "^$weeknr\ " "$WEEKLY_DATA_FILE" | cut -d " " -f 2-)
  dayofweek=$(date -d "$DISPLAY_DATE" +"%u")
  delta=$((1 - dayofweek))
  startofweek=$(date -d "$DISPLAY_DATE -$delta days" +"%D")
  # loop over files
  sef=$({
    set -- $files
    for file in "$@"; do
      file="$ROOT/$file"
      awk \
        -v collection_labels="$COLLECTION_LABELS" \
        "$AWK_PARSE" "$file"
    done
  })
  if [ -n "$sef" ]; then
    sef=$(echo "$sef" | while IFS= read -r line; do
      set -- $line
      starttime="$1"
      shift
      endtime="$1"
      shift
      #fpath="$1"
      shift
      description="$*"
      for i in $(seq 0 7); do
        daystart=$(date -d "$startofweek +$i days 00:00:00" +"%s")
        dayend=$(date -d "$startofweek +$i days 23:59:59" +"%s")
        if [ "$starttime" -gt "$daystart" ] && [ "$starttime" -lt "$dayend" ]; then
          s=$(date -d "@$starttime" +"%H:%M")
          s="$s -"
        elif [ "$starttime" -le "$daystart" ] && [ "$endtime" -gt "$daystart" ]; then
          s="00:00 -"
        else
          continue
        fi
        if [ "$endtime" -gt "$daystart" ] && [ "$endtime" -lt "$dayend" ]; then
          e=$(date -d "@$endtime" +"%H:%M")
          e="- $e"
        elif [ "$endtime" -ge "$dayend" ] && [ "$starttime" -lt "$dayend" ]; then
          e="- 00:00"
        else
          continue
        fi
        echo "$i $s$e >$description"
      done
    done)
  fi
  sef=$({
    echo "$sef"
    seq 0 7
  } | sort -n)
  echo "$sef" | awk -v startofweek="$startofweek" "$AWK_WEEKVIEW"
}

# __view_all()
# This function prints all entries.
#
# @req $APPROX_DATA_FILE:  Filename of approximate data (see `__refresh_data` and `__load_approx_data`)
__view_all() {
  cat "$APPROX_DATA_FILE"
}

###
### Command-line Arguments for reloading views
###   --reload-day
###   --reload-week
###   --reload-all
###

# --reload-day
# Reload view of specified day.
#
# @input $2.. (optional): Specification of day, defaults to `today`
if [ "${1:-}" = "--reload-day" ]; then
  shift
  DISPLAY_DATE=${*:-today}
  __view_day
  exit
fi

# --reload-week
# Reload view of the week containing the specified date.
#
# @input $2.. (optional): Specification of day, defaults to `today`
if [ "${1:-}" = "--reload-week" ]; then
  shift
  DISPLAY_DATE=${*:-today}
  DISPLAY_POS=$((8 - $(date -d "$DISPLAY_DATE" +"%u")))
  __view_week
  exit
fi

# --reload-all
# Reload view of all entries.
if [ "${1:-}" = "--reload-all" ]; then
  __view_all
  exit
fi

###
### Load Configuration
###   ROOT:                 Directory containing the collections
###   COLLECTION_LABELS:    Mappings between collections and labels
###   SYNC_CMD (optional):  Synchronization command
###   DAY_START (optional): Hour of start of the day (defaults to 8)
###   DAY_END (optional):   Hour of end of the day (defaults to 18)
###   EDITOR (optional):    Your favorite editor, is usually already exported
###   TZ (optional):        Your favorite timezone, usually system's choice
###   LC_TIME (optional):   Your favorite locale for date and time
###   ZI_DIR (optional):    Location of tzdata, defaults to /usr/share/zoneinfo
###

CONFIGFILE="$HOME/.config/fzf-vcal/config"
if [ ! -f "$CONFIGFILE" ]; then
  err "Configuration '$CONFIGFILE' not found."
  exit 1
fi
# shellcheck source=/dev/null
. "$CONFIGFILE"
if [ -z "${ROOT:-}" ] || [ -z "${COLLECTION_LABELS:-}" ]; then
  err "Configuration is incomplete."
  exit 1
fi
SYNC_CMD=${SYNC_CMD:-echo 'Synchronization disabled'}
DAY_START=${DAY_START:-8}
DAY_END=${DAY_END:-18}
ZI_DIR=${ZI_DIR:-/usr/share/zoneinfo/posix}
if [ ! -d "$ZI_DIR" ]; then
  err "Could not determine time-zone information"
  exit 1
fi

###
### Check and load required tools
###   FZF:     Fuzzy finder `fzf``
###   UUIDGEN: Tool `uuidgen` to generate random uids
###   CAT:     `bat` or `batcat` or `cat`
###   GIT:     `git` if it exists
###
### The presence of POSIX tools is not checked.
###

if command -v "fzf" >/dev/null; then
  FZF="fzf --black"
else
  err "Did not find the command-line fuzzy finder fzf."
  exit 1
fi

if command -v "uuidgen" >/dev/null; then
  UUIDGEN="uuidgen"
else
  err "Did not find the uuidgen command."
  exit 1
fi

if command -v "bat" >/dev/null; then
  CAT="bat"
elif command -v "batcat" >/dev/null; then
  CAT="batcat"
fi
CAT=${CAT:+$CAT --color=always --style=numbers --language=md}
CAT=${CAT:-cat}

if command -v "git" >/dev/null && [ -d "$ROOT/.git" ]; then
  GIT="git -C $ROOT"
fi

###
### AWK scripts
###   AWK_APPROX:   Generate approximate data of all files
###   AWK_CALSHIFT: Shift calendar to start weeks on Mondays
###   AWK_CALANNOT: Annotate calendar
###   AWK_DAYVIEW:  Generate view of the day
###   AWK_GET:      Print field of iCalendar file
###   AWK_MERGE:    Generate list of weeks with associated iCalendar files
###   AWK_NEW:      Make new iCalendar file
###   AWK_PARSE:    Timezone aware parsing of iCalendar file for day view
###   AWK_UPDATE:   Update iCalendar file
###   AWK_WEEKVIEW: Generate view of the week
###

# TODO: Complete documentation
AWK_APPROX=$(
  cat <<'EOF'
@@include src/awk/approx.awk
EOF
)

AWK_MERGE=$(
  cat <<'EOF'
@@include src/awk/merge.awk
EOF
)

AWK_PARSE=$(
  cat <<'EOF'
@@include src/awk/parse.awk
EOF
)

AWK_WEEKVIEW=$(
  cat <<'EOF'
@@include src/awk/weekview.awk
EOF
)

AWK_DAYVIEW=$(
  cat <<'EOF'
@@include src/awk/dayview.awk
EOF
)

AWK_GET=$(
  cat <<'EOF'
@@include src/awk/get.awk
EOF
)

AWK_UPDATE=$(
  cat <<'EOF'
@@include src/awk/update.awk
EOF
)

AWK_NEW=$(
  cat <<'EOF'
@@include src/awk/new.awk
EOF
)

AWK_CALSHIFT=$(
  cat <<'EOF'
@@include src/awk/calshift.awk
EOF
)

AWK_CALANNOT=$(
  cat <<'EOF'
@@include src/awk/calannot.awk
EOF
)

###
### Colors
###
#GREEN="\033[1;32m"
#RED="\033[1;31m"
WHITE="\033[1;97m"
CYAN="\033[1;36m"
ITALIC="\033[3m"
#FAINT="\033[2m"
OFF="\033[m"

###
### Loading functions
###   __load_approx_data
###   __load_weeks
###   __refresh_data
###

# __load_approx_data()
# Print approximate data from iCalendar files in `$ROOT`
# TODO: Make safe and POSIX compliant
#
# @req $ROOT:              Path that contains the collections (see configuration)
# @req $COLLECTION_LABELS: Mapping between collections and lables (see configuration)
# @req $AWK_APPROX:        Awk script for approximation
__load_approx_data() {
  find "$ROOT" -type f -name '*.ics' -print0 |
    xargs -0 -P0 \
      awk \
      -v collection_labels="$COLLECTION_LABELS" \
      "$AWK_APPROX"
}

# __load_weeks()
# For every relevant week, print associated iCalendar files
#
# @req $APPROX_DATA_FILE:  Filename of approximate data (see `__refresh_data` and `__load_approx_data`)
# @req $AWK_MERGE:         Merge awk script
__load_weeks() {
  dates=$(awk -F'|' '{ print $2; print $3 }' "$APPROX_DATA_FILE")
  file_dates=$(mktemp)
  echo "$dates" | date --file="/dev/stdin" +"%G|%V" >"$file_dates"
  awk "$AWK_MERGE" "$file_dates" "$APPROX_DATA_FILE"
  rm "$file_dates"
}

# __refresh_data()
# Refresh approximate data and per-week data.
#
# This functions stores the output of `__load_approx_data` in the temporary
# file `$APPROX_DATA_FILE` and the output of `__load_weeks` in the temporary
# file `@WEEKLY_DATA_FILE`.
__refresh_data() {
  if [ -n "${APPROX_DATA_FILE:-}" ]; then
    rm -f "$APPROX_DATA_FILE"
  fi
  if [ -n "${WEEKLY_DATA_FILE:-}" ]; then
    rm -f "$WEEKLY_DATA_FILE"
  fi
  APPROX_DATA_FILE=$(mktemp)
  __load_approx_data >"$APPROX_DATA_FILE"
  WEEKLY_DATA_FILE=$(mktemp)
  __load_weeks >"$WEEKLY_DATA_FILE"
  trap 'rm -f "$APPROX_DATA_FILE" "$WEEKLY_DATA_FILE"' EXIT INT
}

###
### UX helper functions
###   __datetime_human_machine
###

# __datetime_human_machine()
# Print date or datetime in a human and machine readable form.
#
# @input $1: Seconds since epoch
__datetime_human_machine() {
  s="$1"
  t=$(date -d "@$s" +"%R")
  dfmt="%F"
  if [ "$t" != "00:00" ]; then
    dfmt="$dfmt %R"
  fi
  date -d "@$s" +"$dfmt"
}

###
### iCalendar modification wrapper
###
###   __edit
###   __new
###   __delete

# __edit()
# Edit iCalendar file.
#
# @input $1: Start date/date-time
# @input $2: End date/date-time
# @input $3: Path to iCalendar file (relative to `$ROOT`)
# @req $AWK_GET:    Awk script to extract fields from iCalendar file
# @req $AWK_UPDATE: Awk script to update iCalendar file
# @req $EDITOR:     Environment variable of your favorite editor
__edit() {
  start=$(__datetime_human_machine "$1")
  end=$(__datetime_human_machine "$2")
  fpath="$ROOT/$3"
  location=$(awk -v field="LOCATION" "$AWK_GET" "$fpath")
  summary=$(awk -v field="SUMMARY" "$AWK_GET" "$fpath")
  description=$(awk -v field="DESCRIPTION" "$AWK_GET" "$fpath")
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
  checksum=$(cksum "$filetmp")
  $EDITOR "$filetmp" >/dev/tty

  # Update only if changes are detected
  if [ "$checksum" != "$(cksum "$filetmp")" ]; then
    filenew="$filetmp.ics"
    if awk "$AWK_UPDATE" "$filetmp" "$fpath" >"$filenew"; then
      mv "$filenew" "$fpath"
      if [ -n "${GIT:-}" ]; then
        $GIT add "$fpath"
        $GIT commit -m "Modified event" -- "$fpath"
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

# __new()
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
# @req $COLLECTION_LABELS: Mapping between collections and lables (see configuration)
# @req $UUIDGEN:           `uuidgen` command
# @req $ROOT:              Path that contains the collections (see configuration)
# @req $EDITOR:            Environment variable of your favorite editor
# @req $AWK_GET:           Awk script to extract fields from iCalendar file
# @req $AWK_new:           Awk script to generate iCalendar file
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
        $GIT commit -m "Added event" -- "$fpath"
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

# __delete()
# Delete iCalendar file
#
# @input $1: Path to iCalendar file, relative to `$ROOT`
# @req $ROOT: Path that contains the collections (see configuration)
# @req $AWK_GET: Awk script to extract fields from iCalendar file
__delete() {
  fpath="$ROOT/$1"
  summary=$(awk -v field="SUMMARY" "$AWK_GET" "$fpath")
  while true; do
    printf "Do you want to delete the entry with the title \"%s\"? (yes/no): " "$summary" >/dev/tty
    read -r yn
    case $yn in
    "yes")
      rm -v "$fpath"
      if [ -n "${GIT:-}" ]; then
        $GIT add "$fpath"
        $GIT commit -m "Deleted event" -- "$fpath"
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

###
### Extra command-line options
###   --import
###   --git
###   --git-init
###

# --import
# Import iCalendar file.
#
# @input $2: Absolute path to iCalendar file
# @req $COLLECTION_LABELS: Mapping between collections and lables (see configuration)
# @req $AWK_PARSE: Parse awk script
# @req $AWK_GET: Awk script to extract fields from iCalendar file
# @req $ROOT: Path that contains the collections (see configuration)
# @req $UUIDGEN: `uuidgen` command
# @req $FZF: `fzf` command
# @req $CAT: Program to print
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
      fpath=""
      while [ -f "$fpath" ] || [ -z "$fpath" ]; do
        uuid=$($UUIDGEN)
        fpath="$ROOT/$collection/$uuid.ics"
      done
      cp -v "$file" "$fpath"
      if [ -n "${GIT:-}" ]; then
        $GIT add "$fpath"
        $GIT commit -m "Imported event" -- "$fpath"
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
  rm -f "$filetmp"
  exit
fi

# --git
# Run git command
#
# @input $2..: Git command
# @req $GIT: git command with `-C` flag set
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
#
# --git-init
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

### Start
__refresh_data

### Exports
# The preview calls run in subprocesses. These require the following variables:
export ROOT CAT AWK_GET AWK_CALSHIFT AWK_CALANNOT CYAN WHITE ITALIC OFF
# The reload commands also run in subprocesses, and use in addition
export COLLECTION_LABELS DAY_START DAY_END AWK_DAYVIEW AWK_WEEKVIEW AWK_PARSE
# as well as the following variables that will be dynamically specified. So, we
# export them in the main loop using the following function.

# __export()
# Re-export dynamical variables to subshells.
__export() {
  export DISPLAY_DATE WEEKLY_DATA_FILE APPROX_DATA_FILE
  if [ -n "${TZ:-}" ]; then
    export TZ
  fi
}

###
### Main loop with the command-line argument
###   --today
###   --yesterday
###   --tomorrow
###   --goto
###   --new <optional date/date-time argument>
###   --day <optional date/date-time argument>
###   --week <optional date/date-time argument>
###   --set-tz
###
### The command-line argument defaults to "--week today".

while true; do
  export DISPLAY_DATE WEEKLY_DATA_FILE APPROX_DATA_FILE

  case "${1:-}" in
  --today | --yesterday | --tomorrow | --goto | --new | --day | --week | --set-tz) ;;
  *)
    DISPLAY_DATE="today"
    set -- "--week" "$DISPLAY_DATE"
    ;;
  esac

  if [ "$1" = "--today" ]; then
    DISPLAY_DATE="today"
    set -- "--day" "$DISPLAY_DATE"
  fi

  if [ "$1" = "--yesterday" ]; then
    DISPLAY_DATE="yesterday"
    set -- "--day" "$DISPLAY_DATE"
  fi

  if [ "$1" = "--tomorrow" ]; then
    DISPLAY_DATE="tomorrow"
    set -- "--day" "$DISPLAY_DATE"
  fi

  if [ "$1" = "--goto" ]; then
    DISPLAY_DATE=""
    while [ -z "${DISPLAY_DATE:-}" ]; do
      printf "Enter date you want to jump to, e.g., today + 1 month or 2024-1-14: " >/dev/tty
      read -r tmp
      if date -d "$tmp" >/dev/null; then
        DISPLAY_DATE="$(date -d "$tmp" +"%D")"
      fi
    done
    set -- "--day" "$DISPLAY_DATE"
  fi

  if [ "$1" = "--set-tz" ]; then
    new_tz=$(find "$ZI_DIR" -type f | sed "s|^$ZI_DIR/*||" | $FZF)
    if [ -n "$new_tz" ]; then
      TZ="$new_tz"
      __refresh_data
      __export
    fi
    shift
  fi

  if [ "${1:-}" = "--new" ]; then
    __new "${2:-}"
    if [ -n "$start" ]; then
      DISPLAY_DATE="$start"
    else
      DISPLAY_DATE="${2:-}"
    fi
    __refresh_data
    __export
    set -- "--day" "$DISPLAY_DATE"
  fi

  if [ "$1" = "--day" ]; then
    DISPLAY_DATE="${2:-today}"
    __export
    selection=$(
      __view_day |
        $FZF \
          --reverse \
          --ansi \
          --no-sort \
          --no-input \
          --margin='20%,5%' \
          --border='double' \
          --color=label:bold:green \
          --border-label-pos=3 \
          --list-border="top" \
          --list-label-pos=3 \
          --cycle \
          --delimiter='|' \
          --with-nth='{6}' \
          --accept-nth='1,2,3,4,5' \
          --preview="$0 --preview-event {}" \
          --expect="ctrl-n,ctrl-t,ctrl-g,ctrl-alt-d,esc,backspace,q,alt-v" \
          --bind="load:pos(1)+transform(
              echo change-border-label:🗓️ \$(date -d {1} +\"%A %e %B %Y\")
            )+transform(
              [ -n \"\${TZ:-}\" ] && echo \"change-list-label:\$WHITE\$ITALIC(\$TZ)\$OFF\"
            )+transform(
              [ -n \"\$(echo {} | cut -d '|' -f 5)\" ] && echo show-preview
            )" \
          --bind="start:hide-preview" \
          --bind="j:down+hide-preview+transform([ -n \"\$(echo {} | cut -d '|' -f 5)\" ] && echo show-preview)" \
          --bind="k:up+hide-preview+transform([ -n \"\$(echo {} | cut -d '|' -f 5)\" ] && echo show-preview)" \
          --bind="ctrl-j:down+hide-preview+transform([ -n \"\$(echo {} | cut -d '|' -f 5)\" ] && echo show-preview)" \
          --bind="ctrl-k:up+hide-preview+transform([ -n \"\$(echo {} | cut -d '|' -f 5)\" ] && echo show-preview)" \
          --bind="down:down+hide-preview+transform([ -n \"\$(echo {} | cut -d '|' -f 5)\" ] && echo show-preview)" \
          --bind="up:up+hide-preview+transform([ -n \"\$(echo {} | cut -d '|' -f 5)\" ] && echo show-preview)" \
          --bind="l:hide-preview+reload:$0 --reload-day {1} '+1 day'" \
          --bind="h:hide-preview+reload:$0 --reload-day {1} '-1 day'" \
          --bind="right:hide-preview+reload:$0 --reload-day {1} '+1 day'" \
          --bind="left:hide-preview+reload:$0 --reload-day {1} '-1 day'" \
          --bind="ctrl-l:hide-preview+reload:$0 --reload-day {1} '+1 week'" \
          --bind="ctrl-h:hide-preview+reload:$0 --reload-day {1} '-1 week'" \
          --bind="alt-l:hide-preview+reload:$0 --reload-day {1} '+1 month'" \
          --bind="alt-h:hide-preview+reload:$0 --reload-day {1} '-1 month'" \
          --bind="ctrl-r:hide-preview+reload:$0 --reload-day today" \
          --bind="ctrl-s:execute($SYNC_CMD ; printf 'Press <enter> to continue.'; read -r tmp)" \
          --bind="w:toggle-preview-wrap" \
          --bind="ctrl-d:preview-down" \
          --bind="ctrl-u:preview-up"
    )
    key=$(echo "$selection" | head -1)
    line=$(echo "$selection" | tail -1)
    if [ "$line" = "$key" ]; then
      line=""
    fi
    DISPLAY_DATE=$(echo "$line" | cut -d '|' -f 1)
    hour=$(echo "$line" | cut -d '|' -f 2)
    start=$(echo "$line" | cut -d '|' -f 3)
    end=$(echo "$line" | cut -d '|' -f 4)
    fpath=$(echo "$line" | cut -d '|' -f 5 | sed "s/ /|/g")
    if [ "$key" = "ctrl-n" ]; then
      if echo "$hour" | grep ":"; then
        hour="$DAY_START"
      fi
      set -- "--new" "$DISPLAY_DATE $hour:00"
    elif [ "$key" = "ctrl-alt-d" ] && [ -n "$fpath" ]; then
      __delete "$fpath"
      __refresh_data
      set -- "--day" "$DISPLAY_DATE"
    elif [ "$key" = "ctrl-g" ]; then
      set -- "--goto"
    elif [ "$key" = "ctrl-t" ]; then
      set -- "--set-tz" "--day" "$DISPLAY_DATE"
    elif [ "$key" = "esc" ] || [ "$key" = "backspace" ] || [ "$key" = "q" ]; then
      set -- "--week" "$DISPLAY_DATE"
    elif [ "$key" = "alt-v" ] && [ -f "$ROOT/$fpath" ]; then
      $EDITOR "$ROOT/$fpath"
    elif [ -z "$key" ] && [ -n "$fpath" ]; then
      __edit "$start" "$end" "$fpath"
      set -- "--day" "$DISPLAY_DATE"
    fi
    __export
  fi

  if [ "${1:-}" = "--week" ]; then
    DISPLAY_DATE="${2:-today}"
    DISPLAY_POS=$((8 - $(date -d "$DISPLAY_DATE" +"%u")))
    __export
    selection=$(
      __view_week |
        $FZF \
          --tac \
          --no-sort \
          --no-hscroll \
          --ellipsis="" \
          --delimiter="|" \
          --with-nth="{4}" \
          --accept-nth=1,2 \
          --ansi \
          --gap 1 \
          --no-scrollbar \
          --no-input \
          --info=right \
          --info-command="printf \"$(date +"%R %Z")\"; [ -n \"\${TZ:-}\" ] && printf \" (\$TZ)\"" \
          --preview-window=up,7,border-bottom \
          --preview="$0 --preview-week {}" \
          --bind="load:pos($DISPLAY_POS)" \
          --expect="ctrl-n,ctrl-g,ctrl-t" \
          --bind="j:down" \
          --bind="k:up" \
          --bind="l:unbind(load)+reload:$0 --reload-week {2} '+1 week'" \
          --bind="h:unbind(load)+reload:$0 --reload-week {2} '-1 week'" \
          --bind="right:unbind(load)+reload:$0 --reload-week {2} '+1 week'" \
          --bind="left:unbind(load)+reload:$0 --reload-week {2} '-1 week'" \
          --bind="ctrl-l:unbind(load)+reload:$0 --reload-week {2} '+1 month'" \
          --bind="ctrl-h:unbind(load)+reload:$0 --reload-week {2} '-1 month'" \
          --bind="alt-l:unbind(load)+reload:$0 --reload-week {2} '+1 year'" \
          --bind="alt-h:unbind(load)+reload:$0 --reload-week {2} '-1 year'" \
          --bind="ctrl-r:rebind(load)+reload($0 --reload-week today)+show-preview" \
          --bind="ctrl-s:execute($SYNC_CMD ; printf 'Press <enter> to continue.'; read -r tmp)" \
          --bind="/:show-input+unbind(j)+unbind(k)+unbind(l)+unbind(h)+unbind(ctrl-l)+unbind(ctrl-h)+unbind(alt-l)+unbind(alt-h)+unbind(load)+hide-preview+reload:$0 --reload-all" \
          --bind="backward-eof:hide-input+rebind(j)+rebind(k)+rebind(l)+rebind(h)+rebind(ctrl-l)+rebind(ctrl-h)+rebind(alt-l)+rebind(alt-h)+rebind(load)+show-preview+reload:$0 --reload-week today" \
          --bind="esc:clear-query+hide-input+rebind(j)+rebind(k)+rebind(l)+rebind(h)+rebind(ctrl-l)+rebind(ctrl-h)+rebind(alt-l)+rebind(alt-h)+rebind(load)+show-preview+reload:$0 --reload-week today"
    )

    key=$(echo "$selection" | head -1)
    line=$(echo "$selection" | tail -1)
    if [ "$line" = "$key" ]; then
      line=""
    fi
    sign=$(echo "$line" | cut -d '|' -f 1)
    DISPLAY_DATE=$(echo "$line" | cut -d '|' -f 2)
    if [ "$key" = "ctrl-n" ]; then
      if [ "$sign" = "~" ]; then
        DISPLAY_DATE=""
      fi
      set -- "--new" "${DISPLAY_DATE:-today} $DAY_START:00"
    elif [ "$key" = "ctrl-g" ]; then
      set -- "--goto"
    elif [ "$key" = "ctrl-t" ]; then
      set -- "--set-tz" "$*"
    else
      if [ "$sign" = "~" ]; then
        set -- "--week" "$DISPLAY_DATE"
      else
        set -- "--day" "$DISPLAY_DATE"
      fi
    fi
    __export
  fi
done
