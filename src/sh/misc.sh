# err()
# This is a helper function to print errors.
#
# @input $1: Error message
err() {
  echo "❌ $1" >/dev/tty
}

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

# Get summary string that can be used in for git-commit messages.
#
# @input $1: iCalendar file path
__summary_for_commit() {
  awk -v field="SUMMARY" "$AWK_GET" "$1" | tr -c -d "[:alnum:][:blank:]" | head -c 15
}

# Re-export dynamical variables to subshells.
__export() {
  DISPLAY_DATE=$(date -R -d "$DISPLAY_DATE")
  export DISPLAY_DATE
  if [ -n "${TZ:-}" ]; then
    export TZ
  fi
}
