# $s|$e|$starttime|$endtime|$fpath|$collection|$description
function allday(collection, desc) {
  return collection " " ITALIC FAINT "    (allday)    " OFF desc
}
function endstoday(stop, collection, desc) {
  return collection " " CYAN "      -- " stop OFF ": " desc
}
function slice(start, stop, collection, desc) {
  if (stop == "00:00")
    return collection " " CYAN start " --      " OFF ": " desc
  else
    return collection " " CYAN start OFF " -- " CYAN stop OFF ": " desc
}
function hrline(hour) {
  hour = hour < 10 ? "0"hour : hour
  print today, hour, "", "", "", "   " FAINT hour ":00           ----------------------" OFF
}
function hrlines(start, stop, h,    starth, stoph, tmp, i) {
  starth = substr(start, 1, 2)
  stoph = substr(stop, 1, 2)
  tmp = substr(start, 4, 2) == "00" ? 0 : 1
  for (i=h; i < starth + tmp && i < dayend; i++)
    hrline(i)
  tmp = substr(stop, 4, 2) == "00" ? 0 : 1
  if (stoph + tmp < daystart)
    return daystart
  else
    return stoph + tmp
}
BEGIN {
  FS = "|"
  GREEN = "\033[1;32m"
  RED = "\033[1;31m"
  WHITE = "\033[1;97m"
  CYAN = "\033[1;36m"
  ITALIC = "\033[3m"
  FAINT = "\033[2m"
  OFF = "\033[m"
  OFS = "|"
}
$1 == "00:00" && $2 == "00:00" { print today, $1, $3, $4, $5, allday($6, $7);        next }
$1 == "00:00"                  { print today, $1, $3, $4, $5, endstoday($2, $6, $7); next }
$1 ~ /^[0-9]{2}:[0-9]{2}$/     {
  daystart = hrlines($1, $2, daystart,    starth, stoph, tmp, i)
  print today, $1, $3, $4, $5, slice($1, $2, $6, $7)
}
END {
  hrlines(dayend":00", 0, daystart,    starth, stoph, tmp, i)
}
