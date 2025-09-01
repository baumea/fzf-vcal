# Preview command-line options
# - --preview-event
# - --preview_week

# Print preview of event and exit.
#
# @input $2: Line from day view containing an event
if [ "${1:-}" = "--preview-event" ]; then
  hour=$(echo "$2" | cut -f 2)
  start=$(echo "$2" | cut -f 3)
  end=$(echo "$2" | cut -f 4)
  fpath=$(echo "$2" | cut -f 5)
  if [ -n "$hour" ] && [ -n "$fpath" ]; then
    fpath="$ROOT/$fpath"
    start=$(datetime_str "$start" "%a ")
    end=$(datetime_str "$end" "%a ")
    location=$(awk -v field="LOCATION" "$AWK_GET" "$fpath")
    status=$(awk -v field="STATUS" "$AWK_GET" "$fpath")
    if [ "$status" = "TENTATIVE" ]; then
      symb="🟡"
    elif [ "$status" = "CANCELLED" ]; then
      symb="❌"
    fi
    echo "📅${symb:-} ${STYLE_EPV_DATETIME}$start${OFF} → ${STYLE_EPV_DATETIME}$end${OFF}"
    if [ -n "${location:-}" ]; then
      echo "📍 ${STYLE_EPV_LOCATION}$location${OFF}"
    fi
    attcnt=$(awk "$AWK_ATTACHLS" "$fpath" | wc -l)
    if [ "$attcnt" -gt 0 ]; then
      echo "🔗 $attcnt attachments"
    fi
    echo ""
    awk -v field="DESCRIPTION" "$AWK_GET" "$fpath" | $CAT
  fi
  exit
fi

# Print preview of week.
#
# @input $2: Line from week view
if [ "${1:-}" = "--preview-week" ]; then
  sign=$(echo "$2" | cut -f 1)
  if [ "$sign" = "+" ]; then
    startdate=$(echo "$2" | cut -f 2)
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
      cal "$month_pre2" "$year_pre2" | awk "$AWK_CALSHIFT" | awk -v cur="${var_pre2:-}" -v style_month="$STYLE_CALENDAR_MONTH" -v style_weekdays="$STYLE_CALENDAR_WEEKDAYS" -v style_cur="$STYLE_CALENDAR_CURRENT_DAY" -v style_highlight="$STYLE_CALENDAR_HL_DAY" -v style_weekdays="$STYLE_CALENDAR_WEEKDAYS" -v style_cur="$STYLE_CALENDAR_CURRENT_DAY" -v style_highlight="$STYLE_CALENDAR_HL_DAY" "$AWK_CALANNOT"
      cal "$month_pre" "$year_pre" | awk "$AWK_CALSHIFT" | awk -v cur="${var_pre:-}" -v style_month="$STYLE_CALENDAR_MONTH" -v style_weekdays="$STYLE_CALENDAR_WEEKDAYS" -v style_cur="$STYLE_CALENDAR_CURRENT_DAY" -v style_highlight="$STYLE_CALENDAR_HL_DAY" "$AWK_CALANNOT"
      cal "$month" "$year" | awk "$AWK_CALSHIFT" | awk -v cur="${var:-}" -v day="$day" -v style_month="$STYLE_CALENDAR_MONTH" -v style_weekdays="$STYLE_CALENDAR_WEEKDAYS" -v style_cur="$STYLE_CALENDAR_CURRENT_DAY" -v style_highlight="$STYLE_CALENDAR_HL_DAY" "$AWK_CALANNOT"
      cal "$month_nex" "$year_nex" | awk "$AWK_CALSHIFT" | awk -v cur="${var_nex:-}" -v style_month="$STYLE_CALENDAR_MONTH" -v style_weekdays="$STYLE_CALENDAR_WEEKDAYS" -v style_cur="$STYLE_CALENDAR_CURRENT_DAY" -v style_highlight="$STYLE_CALENDAR_HL_DAY" "$AWK_CALANNOT"
      cal "$month_nex2" "$year_nex2" | awk "$AWK_CALSHIFT" | awk -v cur="${var_nex2:-}" -v style_month="$STYLE_CALENDAR_MONTH" -v style_weekdays="$STYLE_CALENDAR_WEEKDAYS" -v style_cur="$STYLE_CALENDAR_CURRENT_DAY" -v style_highlight="$STYLE_CALENDAR_HL_DAY" "$AWK_CALANNOT"
      cal "$month_nex3" "$year_nex3" | awk "$AWK_CALSHIFT" | awk -v cur="${var_nex3:-}" -v style_month="$STYLE_CALENDAR_MONTH" -v style_weekdays="$STYLE_CALENDAR_WEEKDAYS" -v style_cur="$STYLE_CALENDAR_CURRENT_DAY" -v style_highlight="$STYLE_CALENDAR_HL_DAY" "$AWK_CALANNOT"
    ) | awk '{ l[(NR-1)%8] = l[(NR-1)%8] "    " $0 } END {for (i in l) print l[i] }'
  fi
  exit
fi
