# Preview helper functions
# - month_previous
# - month_next
# - datetime_str

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
