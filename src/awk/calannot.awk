## src/awk/calannot.awk
## Annotate monthly calendar
##
## @assign cur: Day-of-month to mark as `today`
## @assign day: Day-of-month to highlight

BEGIN {
  BLACK = "\033[1;30m"
  GREEN = "\033[1;32m"
  RED = "\033[1;31m"
  FAINT = "\033[2m"
  BOLD = "\033[1m"
  BG = "\033[41m"
  OFF = "\033[m"
  day = day + 0
  cur = cur + 0
}
NR == 1 { print GREEN $0 OFF; next }
NR == 2 { print FAINT $0 OFF; next }
{ 
  sub("\\y"cur"\\y", BG BLACK BOLD cur OFF)
  sub("\\y"day"\\y", RED BOLD day OFF)
  print
}
