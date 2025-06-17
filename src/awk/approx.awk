## src/awk/approx.awk
## Generate single-line approximate information for every iCalendar argument.
##
## @assign collection_labels: See configuration of the current program.

# Functions

# Unescape string
#
# @local variables: i, c, c2, res
# @input str: String
# @return: Unescaped string
function unescape(str,    i, c, c2, res) {
  for(i=1; i<=length(str);i++) {
    c = substr(str, i, 1)
    if (c != "\\") {
      res = res c
      continue
    }
    i++
    c2 = substr(str, i, 1)
    if (c2 == "n" || c2 == "N") {
      res = res "\n"
      continue
    }
    # Alternatively, c2 is "\\" or "," or ";". In each case, append res with
    # c2. If the strings has been escaped correctly, then the character c2
    # cannot be anything else. To be fail-safe, simply append res with c2.
    res = res c2
  }
  return res
}

# Isolate content part of an iCalendar line, and unescape.
#
# @input str: String
# @return: Unescaped content part
function getcontent(str) {
  return unescape(substr(str, index(str, ":") + 1))
}

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

# Get relative file path.
#
# @local variables: n, a
# @input path: Path to file
# @return: File path of depth 1
function fn(path,    n, a) {
  n = split(path, a, "/")
  return a[n-1] "/" a[n]
}

# Generate title string that will be displayed to user. Here, the start date
# gets a monthly resolution.
#
# @input start: Parsed content of DTSTART field
# @input summary: Content of SUMMARY field
# @return: colorized single-line title string
function title(start, summary) {
  summary = getcontent(summary)
  gsub("\n", " ", summary) # This will be put on a single line
  gsub("\\|",  ":", summary) # we use "|" as delimiter
  depth = split(FILENAME, path, "/")
  collection = depth > 1 ? path[depth-1] : ""
  collection = collection in collection2label ? collection2label[collection] : collection
  return FAINT "~ " collection " " gensub(/^[^0-9]*([0-9]{4})([0-9]{2}).*$/, "\\1-\\2", "1", start) " " summary OFF
}

# AWK program
BEGIN {
  FS="[:;=]"
  OFS="|"
  split(collection_labels, mapping, ";")
  for (map in mapping)
  {
    split(mapping[map], m, "=")
    collection2label[m[1]] = m[2]
  }
  # Colors
  FAINT = "\033[2m"
  OFF = "\033[m"
}
BEGINFILE             { inside = 0; rs = 0; dur = 0; summary = ""; start = "ERROR"; end = "ERROR" }
/^END:VEVENT/         { print "~", start, dur ? start " " end : end, title(start, summary), fn(FILENAME); nextfile }
/^DTSTART/ && inside  { start = parse() }
/^DTEND/ && inside    { end = parse() }
/^DURATION/ && inside { end = parse_duration($NF); dur = 1 }
/^[^ ]/ && rs         { rs = 0 }
/^ / && rs            { summary = summary substr($0, 2) }
/^SUMMARY/ && inside  { rs = 1; summary = $0 }
/^BEGIN:VEVENT/       { inside = 1 }
