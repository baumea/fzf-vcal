function parse(    dt) {
  # Get timezone information
  dt = "";
  for (i=2; i<NF-1; i+=2) {
    if ($i == "TZID") {
      dt = "TZ=\"" $(i+1) "\" ";
      break;
    }
  }
  # Get date/datetime
  return length($NF) == 8 ?
    dt $NF :
    dt gensub(/^([0-9]{8})T([0-9]{2})([0-9]{2})([0-9]{2})(Z)?$/, "\\1 \\2:\\3:\\4\\5", "g", $NF);
}

function parse_duration(    dt, dta, i, n, a, seps) {
  n = split($NF, a, /[PTWHMSD]/, seps);
  delete dta;
  for (i=2; i<=n; i++) {
    if(seps[i] == "W") dta["weeks"]   = a[i];
    if(seps[i] == "H") dta["hours"]   = a[i];
    if(seps[i] == "M") dta["minutes"] = a[i];
    if(seps[i] == "S") dta["seconds"] = a[i];
    if(seps[i] == "D") dta["days"]    = a[i];
  }
  dt = a[1] ? a[1] : "+";
  for (i in dta) {
    dt = dt " " dta[i] " " i;
  }
  return dt;
}

function fn(path,    n, a) {
  n = split(path, a, "/");
  return a[n-1] "/" a[n];
}

BEGIN                 { FS="[:;=]"; OFS="|" }
BEGINFILE             { inside = 0; dur = 0; start = "ERROR"; end = "ERROR" }
/^END:VEVENT/         { print start, dur ? start " " end : end, fn(FILENAME,    n, a); nextfile }
/^DTSTART/ && inside  { start = parse(    dt) }
/^DTEND/ && inside    { end = parse(    dt) }
/^DURATION/ && inside { end = parse_duration(    dt, dta, i, n, a, seps); dur = 1 }
/^BEGIN:VEVENT/       { inside = 1 }
