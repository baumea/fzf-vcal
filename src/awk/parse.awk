## src/awk/parse.awk
## Parse iCalendar file and print its key aspects:
## ```
## <start> <end> <fpath> <collection> <status> <summary>
## ```.
##
## @assign collection_labels: See configuration of the current program.

# Functions

# Time-zone aware parsing of the date/date-time entry at the current record.
#
# @local variables: dt
# @return: date or date-time string that can be used in date (1)
function parse(    dt) {
  # Get timezone information
  for (i=2; i<NF-1; i+=2) {
    if ($i == "TZID") {
      dt = "TZ=\"" $(i+1) "\" "
      break
    }
  }
  # Get date/date-time
  return length($NF) == 8 ?
    dt $NF :
    dt gensub(/^([0-9]{8})T([0-9]{2})([0-9]{2})([0-9]{2})(Z)?$/, "\\1 \\2:\\3:\\4\\5", "g", $NF)
}

# Map iCalendar duration specification into the format to be used in date (1).
#
# @local variables: dt, dta, i, n, a, seps
# @input duration: iCalendar duration string
# @return: relative-date/date-time specification to be used in date (1)
function parse_duration(duration,    dt, dta, i, n, a, seps) {
  n = split(duration, a, /[PTWHMSD]/, seps)
  for (i=2; i<=n; i++) {
    if(seps[i] == "W") dta["weeks"]   = a[i]
    if(seps[i] == "H") dta["hours"]   = a[i]
    if(seps[i] == "M") dta["minutes"] = a[i]
    if(seps[i] == "S") dta["seconds"] = a[i]
    if(seps[i] == "D") dta["days"]    = a[i]
  }
  dt = a[1] ? a[1] : "+"
  for (i in dta)
    dt = dt " " dta[i] " " i
  return dt
}

# Print string of parsed data.
#
# @local variables: cmd, collection, depth, path
# @input start: Start time of event
# @input dur: Boolean that indicates that `end` specifies a duration
# @input end: End time of event, or event duration (see `dur`)
# @input summary: Content of SUMMARY field of the event
function print_data(start, dur, end, summary,    cmd, collection, depth, path) {
  summary = substr(summary, index(summary, ":") + 1)
  gsub("\\\\n",    " ",  summary) # one-liner
  gsub("\\\\N",    " ",  summary) # one-liner
  gsub("\\\\,",    ",",  summary)
  gsub("\\\\;",    ";",  summary)
  gsub("\\\\\\\\", "\\", summary)
  depth = split(FILENAME, path, "/")
  fpath = path[depth-1] "/" path[depth]
  collection = depth > 1 ? path[depth-1] : ""
  collection = collection in collection2label ? collection2label[collection] : collection
  collection = collection2label[path[depth-1]]
  end = dur ? start " " end : end
  cmd = "date -d '" start "' +\"%s\""
  cmd | getline start
  close(cmd)
  cmd = "date -d '" end "' +\"%s\""
  cmd | getline end
  close(cmd)
  status = status ? status : "CONFIRMED"
  print start, end, fpath, collection, status, summary
}

# AWK program
BEGIN { 
  FS="[:;=]"
  split(collection_labels, mapping, ";")
  for (map in mapping)
  {
    split(mapping[map], m, "=")
    collection2label[m[1]] = m[2]
  }
}
/^END:VEVENT/ && inside { print_data(start, dur, end, summary); exit }
/^DTSTART/ && inside    { start = parse() }
/^DTEND/ && inside      { end = parse() }
/^DURATION/ && inside   { end = parse_duration($NF); dur = 1 }
/^STATUS/ && inside     { status = $NF }
/^[^ ]/ && rs           { rs = 0 }
/^ / && rs              { summary = summary substr($0, 2) }
/^SUMMARY/ && inside    { rs = 1; summary = $0 }
/^BEGIN:VEVENT/         { inside = 1 }
