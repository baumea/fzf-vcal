#!/bin/sh

set -eu

if [ "${1:-}" = "--help" ]; then
  cat <<EOF
Usage: $0 [OPTION]

You may specify at most one of the following options:
  --help                 Show this help and exit
  --today                Show today's appointments
  --yesterday            Show yesterday's appointments
  --tomorrow             Show tomorrow's appointments
  --goto                 Interactively enter date to jump to
  --new [date/date-time] Create new entry (today)
  --day [date]           Show appointments of specified day (today)
  --week [date]          Show week of specified date (today)
  --import file          Import iCalendar file
  --import-ni file       Import iCalendar file non-interactively
  --git cmd              Run git command cmd relative to calendar root
  --git-init             Enable the use of git

You may also start this program with setting locale and timezone information.

For instance, to see and modify all of your calendar entries from the
  perspective of Saigon, run
TZ='Asia/Saigon' $0

Likewise, you may see your calendar in the Greek language with
LC_TIME=el_GR.UTF-8 $0
EOF
  exit
fi

# Configuration
. "sh/config.sh"

# Theme
. "sh/theme.sh"

# Misc helper functions
. "sh/misc.sh"

# Preview utilities
. "sh/preview.sh"

# Preview command-line options
. "sh/clipreview.sh"

# View utilities
. "sh/view.sh"

# Reloading command-line options
. "sh/clireload.sh"

# Access to awk scripts
. "sh/awkscripts.sh"

# Functions to load calendar data
. "sh/load.sh"

# Functions to modify iCalendar files
. "sh/icalendar.sh"

# Extra, run-and-exit command-line options
. "sh/cliextra.sh"

### Start
__refresh_data

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
          --delimiter='\t' \
          --with-nth='{6}' \
          --accept-nth='1,2,3,4,5' \
          --preview="$0 --preview-event {}" \
          --expect="ctrl-n,ctrl-t,ctrl-g,ctrl-alt-d,esc,backspace,q,alt-v,x,c,a" \
          --bind='load:pos(1)+transform(
              echo change-border-label:🗓️ $(date -d {1} +"%A %e %B %Y")
            )+transform(
              [ -n "${TZ:-}" ] && echo "change-list-label:$STYLE_DV_TZ($TZ)$OFF"
            )+transform(
              [ -n {5} ] && echo show-preview
            )' \
          --bind="start:hide-preview" \
          --bind="j:down" \
          --bind="k:up" \
          --bind="l:reload:$0 --reload-day {1} '+1 day'" \
          --bind="h:reload:$0 --reload-day {1} '-1 day'" \
          --bind="right:reload:$0 --reload-day {1} '+1 day'" \
          --bind="left:reload:$0 --reload-day {1} '-1 day'" \
          --bind="ctrl-l:reload:$0 --reload-day {1} '+1 week'" \
          --bind="ctrl-h:reload:$0 --reload-day {1} '-1 week'" \
          --bind="alt-l:reload:$0 --reload-day {1} '+1 month'" \
          --bind="alt-h:reload:$0 --reload-day {1} '-1 month'" \
          --bind="ctrl-r:reload:$0 --reload-day today" \
          --bind="ctrl-s:execute($SYNC_CMD; [ -n \"${GIT:-}\" ] && ${GIT:-echo} add -A && ${GIT:-echo} commit -am 'Synchronized'; printf 'Press <enter> to continue.'; read -r tmp)" \
          --bind='tab:down' \
          --bind='shift-tab:up' \
          --bind='focus:hide-preview+transform(
            [ "$FZF_KEY" = "tab" ] && [ -z {5} ] && [ "$FZF_POS" -lt "$FZF_TOTAL_COUNT" ] && echo down
            [ "$FZF_KEY" = "shift-tab" ] && [ -z {5} ] && [ "$FZF_POS" -gt "1" ] && echo up
            )+transform(
              [ -n {5} ] && echo show-preview
            )' \
          --bind="w:toggle-preview-wrap" \
          --bind="ctrl-d:preview-down" \
          --bind="ctrl-u:preview-up"
    )
    key=$(echo "$selection" | head -1)
    line=$(echo "$selection" | tail -1)
    if [ "$line" = "$key" ]; then
      line=""
    fi
    DISPLAY_DATE=$(echo "$line" | cut -f 1)
    hour=$(echo "$line" | cut -f 2)
    start=$(echo "$line" | cut -f 3)
    end=$(echo "$line" | cut -f 4)
    fpath=$(echo "$line" | cut -f 5)
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
    elif [ "$key" = "x" ] && [ -f "$ROOT/$fpath" ]; then
      __cancel_toggle "$fpath"
    elif [ "$key" = "c" ] && [ -f "$ROOT/$fpath" ]; then
      __tentative_toggle "$fpath"
    elif [ "$key" = "a" ] && [ -f "$ROOT/$fpath" ]; then
      att=$(
        awk "$AWK_ATTACHLS" "$ROOT/$fpath" |
          $FZF \
            --delimiter="\t" \
            --accept-nth=1,2,3,4 \
            --with-nth="Attachment {1}: \"{2}\" {3} ({5})" \
            --no-sort \
            --tac \
            --margin="30%,30%" \
            --border=bold \
            --border-label="Attachment View     Keys: <enter> open, <ctrl-alt-d> delete, <shift-a> add" \
            --expect="A" \
            --expect="ctrl-c,ctrl-g,ctrl-q,ctrl-d,esc,q,backspace" \
            --print-query \
            --bind="start:hide-input" \
            --bind="ctrl-alt-d:show-input+change-query(ctrl-alt-d)+accept" \
            --bind='load:transform:[ "$FZF_TOTAL_COUNT" -eq 0 ] && echo "unbind(enter)+unbind(ctrl-alt-d)"' \
            --bind="w:toggle-wrap" \
            --bind="j:down" \
            --bind="k:up" ||
          true
      )
      key=$(echo "$att" | head -2 | xargs)
      sel=$(echo "$att" | tail -1)
      if [ "$key" = "ctrl-c" ] ||
        [ "$key" = "ctrl-g" ] ||
        [ "$key" = "ctrl-q" ] ||
        [ "$key" = "ctrl-d" ] ||
        [ "$key" = "esc" ] ||
        [ "$key" = "q" ] ||
        [ "$key" = "backspace" ]; then
        continue
      fi
      if [ "$key" = "A" ]; then
        __add_attachment "$fpath"
        __refresh_data
        continue
      fi
      attid=$(echo "$sel" | cut -f 1)
      attname=$(echo "$sel" | cut -f 2)
      attfmt=$(echo "$sel" | cut -f 3)
      attenc=$(echo "$sel" | cut -f 4)
      if [ -z "$attid" ]; then
        # This line should be unreachable
        continue
      fi
      if [ "$key" = "ctrl-alt-d" ]; then
        while true; do
          printf "Are you sure you want to delete attachment \"%s\"? (yes/no): " "$attid" >/dev/tty
          read -r yn
          case $yn in
          "yes")
            filetmp=$(mktemp)
            awk -v id="$attid" "$AWK_ATTACHRM" "$ROOT/$fpath" >"$filetmp"
            mv "$filetmp" "$ROOT/$fpath"
            if [ -n "${GIT:-}" ]; then
              $GIT add "$fpath"
              $GIT commit -q -m "Deleted attachment from event '$(__summary_for_commit "$fpath") ...'" -- "$fpath"
            fi
            __refresh_data
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
        continue
      fi
      if [ "$attenc" != "base64" ]; then
        err "Unsupported attachment encoding: $attenc"
        read -r tmp
        continue
      fi
      if [ -n "$attname" ]; then
        tmpdir=$(mktemp -d)
        attpath="$tmpdir/$attname"
      elif [ -n "$attfmt" ]; then
        attext=$(echo "$attfmt" | cut -d "/" -f 2)
        attpath=$(mktemp --suffix="$attext")
      else
        attpath=$(mktemp)
      fi
      # Get file and uncode
      awk -v id="$attid" "$AWK_ATTACHDD" "$ROOT/$fpath" | base64 -d >"$attpath"
      fn=$(file "$attpath")
      while true; do
        printf "Are you sure you want to open \"%s\"? (yes/no): " "$fn" >/dev/tty
        read -r yn
        case $yn in
        "yes")
          $OPEN "$attpath"
          printf "Press <enter> to continue." >/dev/tty
          read -r tmp
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
      # Clean up
      rm -f "$attpath"
      if [ -n "${tmpdir:-}" ] && [ -d "${tmpdir:-}" ]; then
        rm -rf "$tmpdir"
      fi
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
          --delimiter="\t" \
          --with-nth="{4}" \
          --accept-nth=1,2 \
          --ansi \
          --gap 1 \
          --no-scrollbar \
          --no-input \
          --info=right \
          --margin="1" \
          --info-command="printf \"$(date +"%R %Z")\"; [ -n \"\${TZ:-}\" ] && printf \" (\$TZ)\"" \
          --preview-window=up,8,border-bottom \
          --preview="$0 --preview-week {}" \
          --bind="load:pos($DISPLAY_POS)+unbind(load)" \
          --expect="ctrl-n,ctrl-g,ctrl-t" \
          --bind="q:abort" \
          --bind="j:down" \
          --bind="k:up" \
          --bind="l:reload:$0 --reload-week {2} '+1 week'" \
          --bind="h:reload:$0 --reload-week {2} '-1 week'" \
          --bind="right:reload:$0 --reload-week {2} '+1 week'" \
          --bind="left:reload:$0 --reload-week {2} '-1 week'" \
          --bind="ctrl-l:reload:$0 --reload-week {2} '+1 month'" \
          --bind="ctrl-h:reload:$0 --reload-week {2} '-1 month'" \
          --bind="alt-l:reload:$0 --reload-week {2} '+1 year'" \
          --bind="alt-h:reload:$0 --reload-week {2} '-1 year'" \
          --bind="ctrl-r:rebind(load)+reload($0 --reload-week today)+show-preview" \
          --bind="ctrl-s:execute($SYNC_CMD; [ -n \"${GIT:-}\" ] && ${GIT:-echo} add -A && ${GIT:-echo} commit -am 'Synchronized'; printf 'Press <enter> to continue.'; read -r tmp)" \
          --bind="/:show-input+unbind(q)+unbind(j)+unbind(k)+unbind(l)+unbind(h)+unbind(ctrl-l)+unbind(ctrl-h)+unbind(alt-l)+unbind(alt-h)+unbind(load)+hide-preview+reload:$0 --reload-all" \
          --bind="backward-eof:hide-input+rebind(q)+rebind(j)+rebind(k)+rebind(l)+rebind(h)+rebind(ctrl-l)+rebind(ctrl-h)+rebind(alt-l)+rebind(alt-h)+rebind(load)+show-preview+reload:$0 --reload-week today" \
          --bind="esc:clear-query+hide-input+rebind(q)+rebind(j)+rebind(k)+rebind(l)+rebind(h)+rebind(ctrl-l)+rebind(ctrl-h)+rebind(alt-l)+rebind(alt-h)+rebind(load)+show-preview+reload:$0 --reload-week today"
    )

    key=$(echo "$selection" | head -1)
    line=$(echo "$selection" | tail -1)
    if [ "$line" = "$key" ]; then
      line=""
    fi
    sign=$(echo "$line" | cut -f 1)
    DISPLAY_DATE=$(echo "$line" | cut -f 2)
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
