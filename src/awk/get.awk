## src/awk/get.awk
## Print content of a field of an iCalendar file.
##
## @assign field: Field name

@include "lib/awk/icalendar.awk"

BEGIN              { FS = ":"; regex = "^" field }
                   { gsub("\r", "") }
/^BEGIN:VEVENT$/   { inside = 1 }
/^END:VEVENT$/     { exit }
$0 ~ regex         { content = $0; next }
/^ / && content    { content = content substr($0, 2); next }
/^[^ ]/ && content { exit }
END {
  if (!inside) { exit }
  # Process content line
  print getcontent(content)
}
