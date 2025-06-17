## src/awk/new.awk
## Generate iCalendar file from markdown description.
##
## @assign uid: UID to use

# Functions

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

# AWK program
BEGIN { 
  FS=":"
  zulu = strftime("%Y%m%dT%H%M%SZ", systime(), 1)
}
readdesc { desc = desc ? desc "\\n" escape($0) : escape($0); next }
{
  from = substr($0, 1, 6) == "::: |>" ? substr($0, 8) : ""
  if (!from)
    exit 1
  getline
  to = substr($0, 1, 6) == "::: <|" ? substr($0, 8) : ""
  if (!to)
    exit 1
  getline
  location = substr($0, 1, 2) == "@ " ? escape(substr($0, 3)) : ""
  if (location) getline
  summary = substr($0, 1, 2) == "# " ? escape(substr($0, 3)) : ""
  if (!summary)
    exit 1
  getline # This line should be empty
  if ($0 != "")
    exit 1
  readdesc = 1
  next
}
END {
  # Sanitize input
  # If nanoseconds are not 0, then we assume user entered "tomorrow" or
  # something the like, and we make this a date entry, as opposed to a
  # date-time entry.
  # Similarly, if the time is 00:00, we make this a date, as opposed to a
  # date-time entry.
  gsub("\"", "\\\"", from)
  cmd = "date -d \"" from "\" +\"%N\""
  cmd | getline n
  close(cmd)
  n = n + 0
  cmd = "date -d \"" from "\" +\"%H%M\""
  cmd | getline t
  close(cmd)
  t = t + 0
  if (n != 0 || t == 0) {
    from_type = "DATE"
    cmd = "date -d \"" from "\" +\"%Y%m%d\""
  } else {
    from_type = "DATE-TIME"
    cmd = "date -d \"" from "\" +\"@%s\" | xargs date -u +\"%Y%m%dT%H%M00Z\" -d"
  }
  suc = cmd | getline from
  close(cmd)
  if (suc != 1) {
    exit 1
  }
  #
  gsub("\"", "\\\"", to)
  cmd = "date -d \"" to "\" +\"%N\""
  cmd | getline n
  close(cmd)
  n = n + 0
  cmd = "date -d \"" to "\" +\"%H%M\""
  cmd | getline t
  close(cmd)
  t = t + 0
  if (n != 0 || t == 0) {
    to_type = "DATE"
    cmd = "date -d \"" to "\" +\"%Y%m%d\""
  } else {
    to_type = "DATE-TIME"
    cmd = "date -d \"" to "\" +\"@%s\" | xargs date -u +\"%Y%m%dT%H%M00Z\" -d"
  }
  suc = cmd | getline to
  close(cmd)
  if (suc != 1) {
    exit 1
  }

  # print ical
  print "BEGIN:VCALENDAR"
  print "VERSION:2.0"
  print "CALSCALE:GREGORIAN"
  print "PRODID:-//fab//awk//EN"
  print "BEGIN:VEVENT"
  print "DTSTAMP:" zulu
  print "UID:" uid
  print "CLASS:PRIVATE"
  print "CREATED:" zulu
  print "SEQUENCE:1"
  print "LAST-MODIFIED:" zulu
  print "STATUS:CONFIRMED"
  print "DTSTART;VALUE=" from_type ":" from
  print "DTEND;VALUE=" to_type ":" to
  if (summary)    print_fold("SUMMARY:",     summary)
  if (desc)       print_fold("DESCRIPTION:", desc)
  if (location)   print_fold("LOCATION:",    location)
  print "END:VEVENT"
  print "END:VCALENDAR"
}
