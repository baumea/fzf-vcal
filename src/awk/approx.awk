## src/awk/approx.awk
##
## Generate single-line approximate information for every iCalendar argument.
## The fields in each line are separated by "\t"
## The fields are the following:
## 1. "~" (constant, indicating that the lines contains approximate information)
## 2. start (this can be used in date (1))
## 3. end (this can be used in date (1)
## 4. string to display
## 5. filename (collection/name)
##
## @assign collection_labels: See configuration of the current program.
## @assign style_line: Style for each line

@include "lib/awk/icalendar.awk"

# Functions

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
  gsub("\n",  " ", summary) # This will be put on a single line
  gsub("\\t", " ", summary) # we use "\t" as delimiter
  depth = split(FILENAME, path, "/")
  collection = depth > 1 ? path[depth-1] : ""
  collection = collection in collection2label ? collection2label[collection] : collection
  return style_line "~ " collection " " gensub(/^[^0-9]*([0-9]{4})([0-9]{2}).*$/, "\\1-\\2", "1", start) " " summary OFF
}

# AWK program
BEGIN {
  FS="[:;=]"
  OFS="\t"
  split(collection_labels, mapping, ";")
  for (map in mapping)
  {
    split(mapping[map], m, "=")
    collection2label[m[1]] = m[2]
  }
  # Colors
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
