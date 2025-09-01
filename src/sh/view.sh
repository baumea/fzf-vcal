# View Functions
# - __view_day
# - __view_week
# - __view_all

# This function prints the view for the day specified in `$DISPLAY_DATE`, in
# the tab-delimited format with the fields:
#  1. start date
#  2. start time
#  3. end time
#  4. file path
#  5. collection
#  6. description
__view_day() {
  weeknr=$(date -d "$DISPLAY_DATE" +"%G:%V:")
  files=$(grep "^$weeknr" "$WEEKLY_DATA_FILE" | cut -f 2)
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
  # $sef holds (space-delimited): <start> <end> <fpath> <collection> <status> <summary>
  today=$(date -d "$DISPLAY_DATE" +"%D")
  if [ -n "$sef" ]; then
    sef=$(echo "$sef" | while IFS= read -r line; do
      set -- $line
      starttime="$1"
      shift
      endtime="$1"
      shift
      fpath="$1" # we will use | as delimiter (need to convert back!)
      shift
      collection="$1"
      shift
      status="$1"
      shift
      description="$*"
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
      printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "$s" "$e" "$starttime" "$endtime" "$fpath" "$collection" "$description" "$status"
    done)
  fi
  echo "$sef" | sort -n | awk \
    -v today="$today" \
    -v daystart="$DAY_START" \
    -v dayend="$DAY_END" \
    -v style_allday="$STYLE_DV_ALLDAY" \
    -v style_timerange="$STYLE_DV_TIME" \
    -v style_confirmed="$STYLE_DV_CONFIRMED" \
    -v style_tentative="$STYLE_DV_TENTATIVE" \
    -v style_cancelled="$STYLE_DV_CANCELLED" \
    -v style_hour="$STYLE_DV_HOUR" \
    -v style_emptyhour="$STYLE_DV_EMPTYHOUR" \
    "$AWK_DAYVIEW"
}

# This function prints the view for the week that contains the day specified in `$DISPLAY_DATE`.
__view_week() {
  weeknr=$(date -d "$DISPLAY_DATE" +"%G:%V:")
  files=$(grep "^$weeknr" "$WEEKLY_DATA_FILE" | cut -f 2)
  dayofweek=$(date -d "$DISPLAY_DATE" +"%u")
  delta=$((1 - dayofweek))
  startofweek=$(date -d "$DISPLAY_DATE -$delta days" +"%D")
  # loop over files
  sef=$({
    printf "%s" "$files" | xargs -d " " -I {} -P0 \
      awk \
      -v collection_labels="$COLLECTION_LABELS" \
      "$AWK_PARSE" "$ROOT/{}"
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
      collection="$1"
      shift
      status="$1"
      shift
      if [ "$status" = "TENTATIVE" ]; then
        symb="$STYLE_WV_TENTATIVE"
      elif [ "$status" = "CANCELLED" ]; then
        symb="$STYLE_WV_CANCELLED"
      else
        symb="$STYLE_WV_CONFIRMED"
      fi
      description="${symb:-}$*$OFF"
      for i in $(seq 0 7); do
        daystart=$(date -d "$startofweek +$i days 00:00:00" +"%s")
        dayend=$(date -d "$startofweek +$i days 23:59:59" +"%s")
        if [ "$starttime" -gt "$daystart" ] && [ "$starttime" -lt "$dayend" ]; then
          s=$(date -d "@$starttime" +"%H:%M")
        elif [ "$starttime" -le "$daystart" ] && [ "$endtime" -gt "$daystart" ]; then
          s="00:00"
        else
          continue
        fi
        if [ "$endtime" -gt "$daystart" ] && [ "$endtime" -lt "$dayend" ]; then
          e=$(date -d "@$endtime" +"%H:%M")
        elif [ "$endtime" -ge "$dayend" ] && [ "$starttime" -lt "$dayend" ]; then
          e="00:00"
        else
          continue
        fi
        printf "%s\t%s\t%s\t%s\n" "$i" "$s" "$e" "$description"
      done
    done)
  fi
  sef=$({
    echo "$sef"
    seq 0 7
  } | sort -n)
  echo "$sef" | awk \
    -v startofweek="$startofweek" \
    -v style_day="$STYLE_WV_DAY" \
    -v style_event_delim="$STYLE_WV_EVENT_DELIM" \
    -v style_summary="$STYLE_WV_SUMMARY" \
    -v style_time="$STYLE_WV_TIME" \
    "$AWK_WEEKVIEW"
}

# This function prints all entries.
__view_all() {
  cat "$APPROX_DATA_FILE"
}
