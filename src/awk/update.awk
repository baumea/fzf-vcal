## src/awk/update.awk
## Update iCalendar file from markdown file.

@include "lib/awk/icalendar.awk"

BEGIN { 
  FS=":"
  zulu = strftime("%Y%m%dT%H%M%SZ", systime(), 1)
}

ENDFILE {
  if (NR == FNR)
  {
    # If nanoseconds are not 0, then we assume user entered "tomorrow" or
    # something the like, and we make this a date entry, as opposed to a
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
  }
}

NR == FNR && readdesc { desc = desc ? desc "\\n" escape($0) : escape($0); next }
NR == FNR {
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

/^END:VEVENT$/ {
  seq = seq ? seq + 1 : 1
  print "SEQUENCE:" seq
  print "LAST-MODIFIED:" zulu
  print "DTSTART;VALUE=" from_type ":" from
  print "DTEND;VALUE=" to_type ":" to
  print_fold("SUMMARY:",     summary)
  print_fold("DESCRIPTION:", desc)
  print_fold("LOCATION:",    location)
  inside = ""
  skipf = 0
}
/^BEGIN:VEVENT$/           { inside = 1 }
/^ / && skipf              { next } # drop this folded line
/^[^ ]/ && skipf           { skipf = 0 }
/^(DTSTART|DTEND|SUMMARY|LOCATION|CATEGORIES|DESCRIPTION|LAST-MODIFIED)/ && inside { skipf = 1; next } # skip for now, we will write updated fields at the end
/^X-ALT-DESC/ && inside    { skipf = 1; next } # skip
/^SEQUENCE/ && inside      { seq = $2; next } # store sequence number and skip
{ print }
