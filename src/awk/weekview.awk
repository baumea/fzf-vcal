## src/awk/weekview.awk
## Print view of all appointments of the current week.
## Generates view from
##   printf "%s\t%s\t%s\t%s\n" "$i" "$s" "$e" "$description"
##
## @assign startofweek: Date of first day in the week
## @assign style_day: Style for dates
## @assign style_event_delim: Event delimiter
## @assign style_summary: Style for summary lines
## @assign style_time: Style for times

# Functions

# Compose line that will display a day in the week.
# 
# @input desc: String with a description of the event
# @return: Single-line string
function c(desc) {
  return style_summary desc OFF "  " style_event_delim
}

# AWK program

BEGIN {
  FS = "\t"
  OFS = "\t"
  OFF = "\033[m"
}
$2 == "00:00" && $3 == "00:00" { dayline = dayline " " c($4); next }
$2 == "00:00"                  { dayline = dayline style_time " → " $3 OFF " " c($4); next }
$3 == "00:00"                  { dayline = dayline style_time " " $2 " → " OFF c($4); next }
NF == 4                        { dayline = dayline style_time " " $2 " – " $3 OFF " " c($4); next }
NF == 1 && dayline             { print "+", startofweek " +" $1-1 " days", "", dayline }
NF == 1 {
  cmd = "date -d '" startofweek " +" $1 " days' +\"%a %e %b %Y\""
  cmd | getline dayline
  close(cmd)
  dayline = style_day dayline ":   " OFF
}
