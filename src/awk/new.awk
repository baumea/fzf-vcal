function escape(str)
{
  gsub("\\\\", "\\\\", str);
  gsub(";",  "\\\\;",    str);
  gsub(",",  "\\\\,",    str);
}

function print_fold(nameparam, content,    i, s)
{
  i = 74 - length(nameparam);
  s = substr(content, 1, i);
  print nameparam s;
  s = substr(content, i+1, 73);
  i = i + 73;
  while (s)
  {
    print " " s;
    s = substr(content, i+1, 73);
    i = i + 73;
  }
}

BEGIN { 
  FS=":"; 
  zulu = strftime("%Y%m%dT%H%M%SZ", systime(), 1);
}
desc { desc = desc "\\n" $0; next; }
{
  from = substr($0, 1, 6) == "::: |>" ? substr($0, 8) : "";
  if (!from)
    exit 1
  getline
  to = substr($0, 1, 6) == "::: <|" ? substr($0, 8) : "";
  if (!to)
    exit 1
  getline
  summary = substr($0, 1, 2) == "# " ? substr($0, 3) : ""
  if (!summary)
    exit 1
  getline # This line should be empty
  getline # First line of description
  desc = $0;
  next;
}
END {
  # Sanitize input
  # If nanoseconds are not 0, then we assume user enterd "tomorrow" or
  # something the like, and we make this a date entry, as opposed to a
  # date-time entry.
  gsub("\"", "\\\"", from)
  cmd = "date -d \"" from "\" +\"%N\"";
  cmd | getline t
  close(cmd)
  t = t + 0
  if (t == 0) {
    from_type = "DATE-TIME"
    cmd = "date -d \"" from "\" +\"@%s\" | xargs date -u +\"%Y%m%dT%H%M00Z\" -d"
  } else {
    from_type = "DATE"
    cmd = "date -d \"" from "\" +\"%Y%m%d\"";
  }
  suc = cmd | getline from
  close(cmd)
  if (suc != 1) {
    exit 1
  }
  #
  gsub("\"", "\\\"", to)
  cmd = "date -d \"" to "\" +\"%N\"";
  cmd | getline t
  close(cmd)
  t = t + 0
  if (t == 0) {
    to_type = "DATE-TIME"
    cmd = "date -d \"" to "\" +\"@%s\" | xargs date -u +\"%Y%m%dT%H%M00Z\" -d"
  } else {
    to_type = "DATE"
    cmd = "date -d \"" to "\" +\"%Y%m%d\"";
  }
  suc = cmd | getline to
  close(cmd)
  if (suc != 1) {
    exit 1
  }
  escape(summary);
  escape(desc);

  # print ical
  print "BEGIN:VCALENDAR";
  print "VERSION:2.0";
  print "CALSCALE:GREGORIAN";
  print "PRODID:-//fab//awk//EN";
  print "BEGIN:VEVENT"
  print "DTSTAMP:" zulu;
  print "UID:" uid;
  print "CLASS:PRIVATE";
  print "CREATED:" zulu;
  print "SEQUENCE:1";
  print "LAST-MODIFIED:" zulu;
  print "STATUS:FINAL";
  print "DTSTART;VALUE=" from_type ":" from
  print "DTEND;VALUE=" to_type ":" to
  if (summary)    print_fold("SUMMARY:",     summary,       i, s);
  if (desc)       print_fold("DESCRIPTION:", desc,          i, s);
  print "END:VEVENT"
  print "END:VCALENDAR"
}
