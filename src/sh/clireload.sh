# Command-line Arguments for reloading views
# - --reload-day
# - --reload-week
# - --reload-all

# Reload view of specified day.
#
# @input $2.. (optional): Specification of day, defaults to `today`
if [ "${1:-}" = "--reload-day" ]; then
  shift
  DISPLAY_DATE=${*:-today}
  __view_day
  exit
fi

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

# Reload view of all entries.
if [ "${1:-}" = "--reload-all" ]; then
  __view_all
  exit
fi
