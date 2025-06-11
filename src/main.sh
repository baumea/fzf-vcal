#!/bin/sh

set -eu
# TODO: Make sensitive to failures. I don't want to miss appointments!
# TODO Ensure safe use of delimiters

err() {
  echo "❌ $1" >/dev/tty
}

if [ -z "${FZF_VCAL_USE_EXPORTED:-}" ]; then
  # Read configuration
  CONFIGFILE="$HOME/.config/fzf-vcal/config"
  if [ ! -f "$CONFIGFILE" ]; then
    err "Configuration '$CONFIGFILE' not found."
    exit 1
  fi
  # shellcheck source=/dev/null
  . "$CONFIGFILE"
  if [ -z "${ROOT:-}" ] || [ -z "${SYNC_CMD:-}" ] || [ -z "${COLLECTION_LABELS:-}" ]; then
    err "Configuration is incomplete."
    exit 1
  fi
  export ROOT
  export SYNC_CMD
  export COLLECTION_LABELS

  DAY_START=${DAY_START:-8}
  DAY_END=${DAY_END:-18}
  export DAY_START
  export DAY_END

  # Tools
  if command -v "fzf" >/dev/null; then
    FZF="fzf --black"
  else
    err "Did not find the command-line fuzzy finder fzf."
    exit 1
  fi
  export FZF

  if command -v "uuidgen" >/dev/null; then
    UUIDGEN="uuidgen"
  else
    err "Did not find the uuidgen command."
    exit 1
  fi
  export UUIDGEN

  if command -v "bat" >/dev/null; then
    CAT="bat"
  elif command -v "batcat" >/dev/null; then
    CAT="batcat"
  fi
  CAT=${CAT:+$CAT --color=always --style=numbers --language=md}
  CAT=${CAT:-cat}
  export CAT

  ### AWK SCRIPTS
  AWK_LINES=$(
    cat <<'EOF'
@@include src/awk/lines.awk
EOF
  )
  export AWK_LINES

  AWK_MERGE=$(
    cat <<'EOF'
@@include src/awk/merge.awk
EOF
  )
  export AWK_MERGE

  AWK_PARSE=$(
    cat <<'EOF'
@@include src/awk/parse.awk
EOF
  )
  export AWK_PARSE

  AWK_WEEKVIEW=$(
    cat <<'EOF'
@@include src/awk/weekview.awk
EOF
  )
  export AWK_WEEKVIEW

  AWK_DAYVIEW=$(
    cat <<'EOF'
@@include src/awk/dayview.awk
EOF
  )
  export AWK_DAYVIEW

  AWK_GET=$(
    cat <<'EOF'
@@include src/awk/get.awk
EOF
  )
  export AWK_GET

  AWK_UPDATE=$(
    cat <<'EOF'
@@include src/awk/update.awk
EOF
  )
  export AWK_UPDATE

  AWK_NEW=$(
    cat <<'EOF'
@@include src/awk/new.awk
EOF
  )
  export AWK_NEW

  AWK_CAL=$(
    cat <<'EOF'
@@include src/awk/cal.awk
EOF
  )
  export AWK_CAL
  ### END OF AWK SCRIPTS

  ## Colors
  export GREEN="\033[1;32m"
  export RED="\033[1;31m"
  export WHITE="\033[1;97m"
  export CYAN="\033[1;36m"
  export ITALIC="\033[3m"
  export FAINT="\033[2m"
  export OFF="\033[m"

  export FZF_VJOUR_USE_EXPORTED="yes"
fi

__load_approx_data() {
  find "$ROOT" -type f -name '*.ics' -print0 |
    xargs -0 -P0 \
      awk \
      -v collection_labels="$COLLECTION_LABELS" \
      "$AWK_LINES"
}

__load_weeks() {
  dates=$(awk -F'|' '{ print $2; print $3 }' "$APPROX_DATA_FILE")
  file_dates=$(mktemp)
  echo "$dates" | date --file="/dev/stdin" +"%s" >"$file_dates"
  awk "$AWK_MERGE" "$file_dates" "$APPROX_DATA_FILE"
  rm "$file_dates"
}

__show_day() {
  weeknr=$(date -d "$DISPLAY_DATE" +"%s")
  weeknr=$(((weeknr - 259200) / 604800)) # shift, because epoch origin is a Thursday
  files=$(grep "^$weeknr " "$WEEKLY_DATA_FILE" | cut -d " " -f 2-)
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
  if [ -n "$sef" ]; then
    today=$(date -d "$DISPLAY_DATE" +"%D")
    sef=$(echo "$sef" | while IFS= read -r line; do
      set -- $line
      starttime="$1"
      shift
      endtime="$1"
      shift
      fpath="$(echo "$1" | sed 's/|/ /g')" # we will use | as delimiter (need to convert back!)
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
      echo "$s|$e|$starttime|$endtime|$fpath|$description"
    done)
  fi
  echo "$sef" | sort -n | awk -v daystart="$DAY_START" -v dayend="$DAY_END" "$AWK_DAYVIEW"
}

__list() {
  weeknr=$(date -d "$DISPLAY_DATE" +"%s")
  weeknr=$(((weeknr - 259200) / 604800)) # shift, because epoch origin is a Thursday
  files=$(grep "^$weeknr " "$WEEKLY_DATA_FILE" | cut -d " " -f 2-)
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
  #seq -f "$startofweek +%g days" 0 6 |
  #  LC_ALL=c xargs -I {} date -d "{}" +"%a %e %b %Y"
}

__canonical_datetime_hm() {
  s="$1"
  t=$(date -d "@$s" +"%R")
  dfmt="%F"
  if [ "$t" != "00:00" ]; then
    dfmt="$dfmt %R"
  fi
  date -d "@$s" +"$dfmt"
}

__canonical_datetime() {
  s="$1"
  shift
  t=$(date -d "@$s" +"%R")
  dfmt="$*%e %b %Y"
  if [ "$t" != "00:00" ]; then
    dfmt="$dfmt %R %Z"
  fi
  date -d "@$s" +"$dfmt"
}

__edit() {
  start=$(__canonical_datetime_hm "$1")
  end=$(__canonical_datetime_hm "$2")
  fpath="$3"
  summary=$(awk -v field="SUMMARY" "$AWK_GET" "$fpath")
  description=$(awk -v field="DESCRIPTION" "$AWK_GET" "$fpath")
  filetmp=$(mktemp --suffix='.md')
  (
    echo "::: |> $start"
    echo "::: <| $end"
    echo "# $summary"
    echo ""
    echo "$description"
  ) >"$filetmp"
  checksum=$(cksum "$filetmp")
  $EDITOR "$filetmp" >/dev/tty

  # Update only if changes are detected
  if [ "$checksum" != "$(cksum "$filetmp")" ]; then
    filenew="$filetmp.ics"
    awk "$AWK_UPDATE" "$filetmp" "$fpath" >"$filenew"
    mv "$filenew" "$fpath"
    __refresh_data
  fi
  rm "$filetmp"
}

__refresh_data() {
  if [ -n "${APPROX_DATA_FILE:-}" ]; then
    rm "$APPROX_DATA_FILE"
  fi
  if [ -n "${WEEKLY_DATA_FILE:-}" ]; then
    rm "$WEEKLY_DATA_FILE"
  fi
  APPROX_DATA_FILE=$(mktemp)
  __load_approx_data >"$APPROX_DATA_FILE"
  export APPROX_DATA_FILE
  WEEKLY_DATA_FILE=$(mktemp)
  __load_weeks >"$WEEKLY_DATA_FILE"
  export WEEKLY_DATA_FILE
}

## Start
if [ "${1:-}" = "--help" ]; then
  echo "Usage: $0 [OPTION]"
  echo ""
  echo "You may specify at most one option."
  echo "  --help                 Show this help and exit"
  echo "  --new                  Create new entry"
  echo "  --today                Show today's appointments"
  echo "  --goto                 Interactively enter date to jump to"
  echo "  --day <day>            Show appointments of specified day"
  echo "  --date <date>          Show week of specified date"
  echo ""
  echo "You may also start this program with setting locale and timezone"
  echo "information. For instance, to see and modify all of your calendar"
  echo "entries from the perspective of Saigon, run"
  echo "TZ='Asia/Saigon' $0"
  echo "Likewise, you may specify the usage of Greek with"
  echo "LC_TIME=el_GR.UTF-8 $0"
  exit
fi

if [ "${1:-}" = "--today" ]; then
  exec $0 --day "today"
fi

if [ "${1:-}" = "--goto" ]; then
  DISPLAY_DATE=""
  while [ -z "$DISPLAY_DATE" ]; do
    printf "Enter date you want to jump to, e.g., today + 1 month or 2024-1-14: " >/dev/tty
    read -r tmp
    if date -d "$tmp"; then
      DISPLAY_DATE="$tmp"
    fi
  done
fi

if [ "${1:-}" = "--new" ]; then
  collection=$(echo "$COLLECTION_LABELS" | tr ';' '\n' | awk '/./ {print}' | $FZF --margin="30%" --no-info --delimiter='=' --with-nth=2 --accept-nth=1)
  fpath=""
  while [ -f "$fpath" ] || [ -z "$fpath" ]; do
    uuid=$($UUIDGEN)
    fpath="$ROOT/$collection/$uuid.ics"
  done
  startsec=$(date -d "${2:-today 8:00}" +"%s")
  endsec=$((startsec + 3600))
  start=$(__canonical_datetime_hm "$startsec")
  end=$(__canonical_datetime_hm "$endsec")
  filetmp=$(mktemp --suffix='.md')
  (
    echo "::: |> $start"
    echo "::: <| $end"
    echo "# <!-- write summary here -->"
    echo ""
  ) >"$filetmp"
  checksum=$(cksum "$filetmp")
  $EDITOR "$filetmp" >/dev/tty

  # Update only if changes are detected
  if [ "$checksum" != "$(cksum "$filetmp")" ]; then
    filenew="$filetmp.ics"
    awk -v uid="$uuid" "$AWK_NEW" "$filetmp" >"$filenew"
    mv "$filenew" "$fpath"
    __refresh_data
  fi
  rm "$filetmp"
fi

if [ -z "${APPROX_DATA_FILE:-}" ]; then
  __refresh_data
fi

if [ "${1:-}" = "--day" ]; then
  DISPLAY_DATE="${2:-today}"
  export DISPLAY_DATE
  selection=$(
    __show_day |
      $FZF \
        --reverse \
        --ansi \
        --no-sort \
        --no-input \
        --margin='20%,5%' \
        --border='double' \
        --border-label="🗓️ $(date -d "$DISPLAY_DATE" +"%A %e %B %Y")" \
        --color=label:bold:green \
        --border-label-pos=3 \
        --cycle \
        --delimiter='|' \
        --with-nth='{5}' \
        --accept-nth='1,2,3,4' \
        --preview="$0 --preview {}" \
        --expect="ctrl-n,esc,backspace,q" \
        --bind='start:hide-preview' \
        --bind='ctrl-j:down+hide-preview+transform:echo {} | grep \|\| || echo show-preview' \
        --bind='ctrl-k:up+hide-preview+transform:echo {} | grep \|\| || echo show-preview' \
        --bind="ctrl-s:execute($SYNC_CMD ; printf 'Press <enter> to continue.'; read -r tmp)" \
        --bind="ctrl-alt-d:become($0 --delete {})" \
        --bind="j:preview-down" \
        --bind="k:preview-down" \
        --bind="w:toggle-preview-wrap"
  )
  key=$(echo "$selection" | head -1)
  line=$(echo "$selection" | tail -1)
  if [ "$line" = "$key" ]; then
    line=""
  fi
  hour=$(echo "$line" | cut -d '|' -f 1)
  start=$(echo "$line" | cut -d '|' -f 2)
  end=$(echo "$line" | cut -d '|' -f 3)
  fpath=$(echo "$line" | cut -d '|' -f 4 | sed "s/ /|/g")
  if [ "$key" = "ctrl-n" ]; then
    if echo "$hour" | grep ":"; then
      hour="$DAY_START"
    fi
    exec $0 --new "$DISPLAY_DATE $hour:00"
  elif [ -z "$key" ] && [ -n "$fpath" ]; then
    fpath="$ROOT/$fpath"
    __edit "$start" "$end" "$fpath"
  fi
fi

if [ "${1:-}" = "--date" ]; then
  DISPLAY_DATE="$2"
fi

if [ "${1:-}" = "--preview" ]; then
  hour=$(echo "$2" | cut -d '|' -f 1)
  start=$(echo "$2" | cut -d '|' -f 2)
  end=$(echo "$2" | cut -d '|' -f 3)
  fpath=$(echo "$2" | cut -d '|' -f 4 | sed "s/ /|/g")
  if [ -n "$hour" ] && [ -n "$fpath" ]; then
    fpath="$ROOT/$fpath"
    start=$(__canonical_datetime "$start" "%a ")
    end=$(__canonical_datetime "$end" "%a ")
    echo "${GREEN}From: ${OFF}${CYAN}$start${OFF}"
    echo "${GREEN}To:   ${OFF}${CYAN}$end${OFF}"
    echo ""
    awk -v field="DESCRIPTION" "$AWK_GET" "$fpath" | $CAT
  fi
  exit
fi

month_previous() {
  month="$1"
  year="$2"
  if [ "$month" -eq 1 ]; then
    month=12
    year=$((year - 1))
  else
    month=$((month - 1))
  fi
  echo "$month $year"
}

month_next() {
  month="$1"
  year="$2"
  if [ "$month" -eq 12 ]; then
    month=1
    year=$((year + 1))
  else
    month=$((month + 1))
  fi
  echo "$month $year"
}

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
      cal "$month_pre2" "$year_pre2" | awk -v cur="${var_pre2:-}" "$AWK_CAL"
      cal "$month_pre" "$year_pre" | awk -v cur="${var_pre:-}" "$AWK_CAL"
      cal "$month" "$year" | awk -v cur="${var:-}" -v day="$day" "$AWK_CAL"
      cal "$month_nex" "$year_nex" | awk -v cur="${var_nex:-}" "$AWK_CAL"
      cal "$month_nex2" "$year_nex2" | awk -v cur="${var_nex2:-}" "$AWK_CAL"
      cal "$month_nex3" "$year_nex3" | awk -v cur="${var_nex3:-}" "$AWK_CAL"
    ) | awk '{ l[NR%8] = l[NR%8] "    " $0 } END {for (i in l) if (i>0) print l[i] }'
  fi
  exit
fi

if [ "${1:-}" = "--delete" ]; then
  fpath=$(echo "$2" | cut -d '|' -f 4 | sed "s/ /|/g")
  if [ -n "$fpath" ]; then
    fpath="$ROOT/$fpath"
    summary=$(awk -v field="SUMMARY" "$AWK_GET" "$fpath")
    while true; do
      printf "Do you want to delete the entry with the title \"%s\"? (yes/no): " "$summary" >/dev/tty
      read -r yn
      case $yn in
      "yes")
        rm -v "$fpath"
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
  fi
  __refresh_data
  exec $0 --day "$DISPLAY_DATE"
fi

if [ "${1:-}" = "--all" ]; then
  cat "$APPROX_DATA_FILE"
  exit
fi

DISPLAY_DATE=${DISPLAY_DATE:-today}
DISPLAY_DATE=$(date -d "$DISPLAY_DATE" +"%D")
DISPLAY_POS=$((8 - $(date -d "$DISPLAY_DATE" +"%u")))

if [ "${1:-}" = "--list" ]; then
  shift
  DISPLAY_DATE=${*:-today}
  DISPLAY_POS=$((8 - $(date -d "$DISPLAY_DATE" +"%u")))
  __list
  exit
fi

selection=$(
  __list |
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
      --info=right \
      --info-command="printf \"$(date +"%R %Z")\"" \
      --preview-window=up,7,border-bottom \
      --preview="$0 --preview-week {}" \
      --expect="ctrl-n" \
      --bind="ctrl-j:transform:[ \$FZF_POS -le 1 ] &&
      echo unbind\(load\)+reload:$0 --list {2} '+1 day'||
      echo down" \
      --bind="ctrl-k:transform:[ \$FZF_POS -ge 7 ] &&
      echo unbind\(load\)+reload:$0 --list {2} '-1 day'||
      echo up" \
      --bind="change:reload($0 --all)+hide-preview" \
      --bind="backward-eof:rebind(load)+reload($0 --list)+show-preview" \
      --bind="load:pos($DISPLAY_POS)" \
      --bind="ctrl-u:unbind(load)+reload:$0 --list {2} '-1 week'" \
      --bind="ctrl-d:unbind(load)+reload:$0 --list {2} '+1 week'" \
      --bind="ctrl-alt-u:unbind(load)+reload:$0 --list {2} '-1 month'" \
      --bind="ctrl-alt-d:unbind(load)+reload:$0 --list {2} '+1 month'" \
      --bind="ctrl-s:execute($SYNC_CMD ; printf 'Press <enter> to continue.'; read -r tmp)" \
      --bind="ctrl-g:become($0 --goto)" \
      --bind="ctrl-l:rebind(load)+reload:$0 --list"
)

key=$(echo "$selection" | head -1)
line=$(echo "$selection" | tail -1)
if [ "$line" = "$key" ]; then
  line=""
fi
sign=$(echo "$line" | cut -d '|' -f 1)
startdate=$(echo "$line" | cut -d '|' -f 2)
if [ "$key" = "ctrl-n" ]; then
  # Add new
  if [ "$sign" = "~" ]; then
    startdate=""
  fi
  exec $0 --new "${startdate:-today} $DAY_START:00"
fi
if [ -z "$key" ] && [ -z "$line" ]; then
  rm "$WEEKLY_DATA_FILE" "$APPROX_DATA_FILE"
  return 0
fi

if [ "$sign" = "~" ]; then
  exec $0 --date "$startdate"
else
  exec $0 --day "$startdate"
fi
echo "Going to end..."
echo "$selection"
echo "STOPPING NOW"
