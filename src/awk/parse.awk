## src/awk/parse.awk
## Parse iCalendar file and print its key aspects:
## ```
## <start> <end> <fpath> <collection> <status> <summary>
## ```.
## The output is space delimited.
## Summary may contain spaces, but it's the last in the list.
##
## @assign collection_labels: See configuration of the current program.

@include "lib/awk/icalendar.awk"

# Print string of parsed data.
#
# @local variables: cmd, collection, depth, path
# @input start: Start time of event
# @input dur: Boolean that indicates that `end` specifies a duration
# @input end: End time of event, or event duration (see `dur`)
# @input summary: Content of SUMMARY field of the event
function print_data(start, dur, end, summary,    cmd, collection, depth, path) {
  summary = getcontent(summary)
  gsub("\n", " ",    summary) # This will be put on a single line
  gsub("\t", "    ", summary) # Generally, we use tab as delimiter.
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
