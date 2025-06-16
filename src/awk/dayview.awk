## src/awk/dayview.awk
## Generate the view of a day from lines of the form
## ```
##  <start_date>|<end_date>|<start_time>|<end_time>|<file_path>|<collection>|<description>
## ```.
##
## @assign today: Date of `today` in the format %D (%m/%d/%y)
## @assign daystart: Hour of start of the day
## @assign dayend: Hour of end of the day

# Functions

# Set event color based on status

# @input status: Event status, one of TENTATIVE, CONFIRMED, CANCELLED
# @return: Color modifier
function color_from_status(status) {
  return status == "CANCELLED" ? STRIKE CYAN : status == "TENTATIVE" ? FAINT CYAN : CYAN
}

# Return line for all-day event.
#
# @local variables: color
# @input collection: Collection symbol
# @input desc: Event description
# @input status: Event status, one of TENTATIVE, CONFIRMED, CANCELLED
# @return: Single-line string
function allday(collection, desc, status,    color) {
  color = color_from_status(status)
  return collection " " LIGHT_CYAN ITALIC FAINT "    (allday)    " OFF color desc OFF
}

# Return line for multi-day event, or event that starts at midnight, which ends today.
#
# @local variables: color
# @input stop: Time at which the event ends
# @input collection: Collection symbol
# @input desc: Event description
# @input status: Event status, one of TENTATIVE, CONFIRMED, CANCELLED
# @return: Single-line string
function endstoday(stop, collection, desc, status) {
  color = color_from_status(status)
  return collection " " LIGHT_CYAN "      -- " stop OFF ": " color desc OFF
}

# Return line for event that starts sometime today.
#
# @local variables: color
# @input start: Time at which the event starts
# @input stop: Time at which the event ends
# @input collection: Collection symbol
# @input desc: Event description
# @input status: Event status, one of TENTATIVE, CONFIRMED, CANCELLED
# @return: Single-line string
function slice(start, stop, collection, desc, status) {
  color = color_from_status(status)
  if (stop == "00:00")
    return collection " " LIGHT_CYAN start " --      " OFF ": " color desc OFF
   else
    return collection " " LIGHT_CYAN start OFF " -- " LIGHT_CYAN stop OFF ": " color desc OFF
}

# Print line for a single hour entry.
#
# @input hour: Hour of the entry
function hrline(hour) {
  hour = hour < 10 ? "0"hour : hour
  print today, hour, "", "", "", "   " FAINT hour ":00           ----------------------" OFF
}

# Print lines for hour entries before an event that starts at `start` and stops
# at `stop`.
#
# @local variables: starth, stoph, tmp, i
# @input start: Time at which the event starts
# @input stop: Time at which the event ends
# @input h: Last event-free hour
# @return: Hour of now last event-free hour
function hrlines(start, stop, h,    starth, stoph, tmp, i) {
  starth = substr(start, 1, 2)
  stoph = substr(stop, 1, 2)
  tmp = substr(start, 4, 2) == "00" ? 0 : 1
  for (i=h; i < starth + tmp && i < dayend; i++)
    hrline(i)
  tmp = substr(stop, 4, 2) == "00" ? 0 : 1
  if (stoph + tmp < daystart)
    return daystart
  else
    return stoph + tmp
}

# AWK program
BEGIN {
  FS = "|"
  LIGHT_CYAN = "\033[1;36m"
  CYAN = "\033[1;36m"
  ITALIC = "\033[3m"
  FAINT = "\033[2m"
  STRIKE = "\033[9m"
  OFF = "\033[m"
  OFS = "|"
}
$1 == "00:00" && $2 == "00:00" { print today, $1, $3, $4, $5, allday($6, $7, $8);        next }
$1 == "00:00"                  { print today, $1, $3, $4, $5, endstoday($2, $6, $7, $8); next }
$1 ~ /^[0-9]{2}:[0-9]{2}$/     {
  daystart = hrlines($1, $2, daystart)
  print today, $1, $3, $4, $5, slice($1, $2, $6, $7, $8)
}
END                            { hrlines(dayend":00", 0, daystart)                        }
