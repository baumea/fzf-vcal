# Loading functions
# - __load_approx_data
# - __load_weeks
# - __refresh_data

# Print approximate data from iCalendar files in `$ROOT`
__load_approx_data() {
  find "$ROOT" -type f -name '*.ics' -print0 |
    xargs -0 -P0 \
      awk \
      -v collection_labels="$COLLECTION_LABELS" \
      -v style_line="$STYLE_LV" \
      "$AWK_APPROX"
}

# For every relevant week, print associated iCalendar files
__load_weeks() {
  dates=$(awk -F'\t' '{ print $2; print $3 }' "$APPROX_DATA_FILE")
  file_dates=$(mktemp)
  echo "$dates" | date --file="/dev/stdin" +"%G:%V:" >"$file_dates"
  awk "$AWK_MERGE" "$file_dates" "$APPROX_DATA_FILE"
  rm "$file_dates"
}

# Refresh approximate data and per-week data.
#
# This functions stores the output of `__load_approx_data` in the temporary
# file `$APPROX_DATA_FILE` and the output of `__load_weeks` in the temporary
# file `@WEEKLY_DATA_FILE`.
__refresh_data() {
  if [ -z "${APPROX_DATA_FILE:-}" ]; then
    APPROX_DATA_FILE=$(mktemp)
    trap 'rm -f "$APPROX_DATA_FILE"' EXIT INT
  fi
  if [ -z "${WEEKLY_DATA_FILE:-}" ]; then
    WEEKLY_DATA_FILE=$(mktemp)
    trap 'rm -f "$WEEKLY_DATA_FILE"' EXIT INT
  fi
  __load_approx_data >"$APPROX_DATA_FILE"
  __load_weeks >"$WEEKLY_DATA_FILE"
}
