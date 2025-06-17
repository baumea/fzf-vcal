## src/awk/weekview.awk
## Print view of all appointments of the current week.
##
## @assign startofweek: Date of first day in the week

# Functions

# Compose line that will display a day in the week.
# 
# @return: Single-line string
function c() {
  return CYAN substr($0, index($0, ">") + 1) OFF "  " RED "/" OFF
}

# AWK program

BEGIN {
  GREEN = "\033[1;32m"
  RED = "\033[1;31m"
  CYAN = "\033[1;36m"
  OFF = "\033[m"
  OFS = "|"
}
/^[0-7] 00:00 -- 00:00/                         { dayline = dayline " " c(); next }
/^[0-7] 00:00 -- /                              { dayline = dayline " → " $4 " " c(); next }
/^[0-7] [0-9]{2}:[0-9]{2} -- 00:00/             { dayline = dayline " " $2 " → " c(); next }
/^[0-7] [0-9]{2}:[0-9]{2} -- [0-9]{2}:[0-9]{2}/ { dayline = dayline " " $2 " – " $4 " " c(); next }
/^[0-7]$/ && dayline                            { print "+", startofweek " +" $0-1 " days", "", dayline }
/^[0-7]$/ {
  cmd = "date -d '" startofweek " +" $0 " days' +\"%a %e %b %Y\""
  cmd | getline dayline
  close(cmd)
  dayline = GREEN dayline ":   " OFF
}
