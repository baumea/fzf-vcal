# Escape string to be used as content in iCalendar files.
#
# @input str: String to escape
# @return: Escaped string
function escape(str)
{
  gsub("\\\\", "\\\\", str)
  gsub(";",    "\\;",  str)
  gsub(",",    "\\,",  str)
  return str
}

# Print property with its content and fold according to the iCalendar
# specification.
#
# @local variables: i, s
# @input nameparam: Property name with optional parameters
# @input content: Escaped content
function print_fold(nameparam, content,    i, s)
{
  i = 74 - length(nameparam)
  s = substr(content, 1, i)
  print nameparam s
  s = substr(content, i+1, 73)
  i = i + 73
  while (s)
  {
    print " " s
    s = substr(content, i+1, 73)
    i = i + 73
  }
}

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
