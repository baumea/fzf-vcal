## src/awk/calannot.awk
## Annotate monthly calendar
##
## @assign cur: Day-of-month to mark as `today`
## @assign day: Day-of-month to highlight
## @assign style_month: Theme to use for month
## @assign style_weekdays: Theme to use for weekdays
## @assign style_cur: Theme to use for current day 
## @assign style_highlight: Theme to use for highlighted day

BEGIN {
  OFF = "\033[m"
  day = day + 0
  cur = cur + 0
}
NR == 1 { print style_month $0 OFF; next }
NR == 2 { print style_weekdays $0 OFF; next }
{ 
  if (day == cur) {
    sub("\\y"cur"\\y", style_highlight style_cur cur OFF)
  } else {
    sub("\\y"cur"\\y", style_cur cur OFF)
    sub("\\y"day"\\y", style_highlight day OFF)
  }
  print
}
