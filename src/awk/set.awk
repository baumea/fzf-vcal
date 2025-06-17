## src/awk/set.awk
## Set or replace the content of a specified field in the iCalendar file.
##
## @assign field: iCalendar field
## @assign value: Content to set it to
##
## LIMITATION: This program does not fold long content lines.

# Functions

# Escape string to be used as content.
#
# @input str: Content string
# @return: Escaped string
function escape(str)
{
  gsub("\\\\", "\\\\", str)
  gsub(";",    "\\;",  str)
  gsub(",",    "\\,",  str)
  return str
}

# AWK program

BEGIN                 { FS = "[:;]"; zulu = strftime("%Y%m%dT%H%M%SZ", systime(), 1) }
/^BEGIN:VEVENT$/      { inside = 1 }
/^END:VEVENT$/        {
  inside = 0
  if (!duplic)
    print field ":" escape(value)
  seq = seq ? seq + 1 : 1
  print "SEQUENCE:" seq
  print "LAST-MODIFIED:" zulu
}
$1 == field && inside { con = 1; duplic = 1; print field ":" escape(value); next }
$1 == field && duplic { con = 1; next }
/^ / && con           { next }
/^[^ ]/ && con        { con = 0 }
/^SEQUENCE/ && inside { seq = $2; next } # store sequence number and skip
/^LAST-MODIFIED/ && inside { next }
{ print }
