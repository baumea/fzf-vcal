## src/awk/get.awk
## Print content of a field of an iCalendar file.
##
## @assign field: Field name

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

# AWK program
BEGIN              { FS = ":"; regex = "^" field }
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
